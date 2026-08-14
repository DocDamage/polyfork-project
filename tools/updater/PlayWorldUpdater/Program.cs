using System.Diagnostics;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace PlayWorldUpdater;

internal static class Program
{
    private const long MaxRequestBytes = 1024 * 1024;
    private const long MaxExpandedBytes = 16L * 1024 * 1024 * 1024;
    private const int MaxArchiveEntries = 50_000;
    private static readonly HashSet<string> ProtectedTopLevel = new(StringComparer.OrdinalIgnoreCase) { "projects", "asset_library", "user_data", "updates", "release", "recovery", "checkpoints", "preferences", "support" };
    private static readonly HashSet<string> JournalStages = new(StringComparer.Ordinal) { "created", "checking", "available", "downloading", "downloaded", "verifying", "verified", "handoff", "waiting_for_shutdown", "backing_up", "replacing", "installer_running", "restart_pending", "completed", "failed", "rollback_pending", "rolled_back", "cancelled" };
    private static string _requestPath = "";
    private static JsonObject _request = new();
    private static JsonObject _journal = new();
    private static string _logPath = "";
    private static string _temporaryExtractRoot = "";

    public static int Main(string[] args)
    {
        try
        {
            var options = ParseArguments(args);
            _requestPath = RequireFullPath(options.GetValueOrDefault("request"), "Request path");
            _request = ReadObject(_requestPath, MaxRequestBytes);
            ValidateRequest(_request);
            _logPath = Path.Combine(Path.GetDirectoryName(_requestPath)!, "PlayWorldUpdater.log");
            if (!options.ContainsKey("relocated")) return RelocateAndLaunch();
            LoadJournal();
            WaitForParent((int)_request["parent_process_id"]!.GetValue<long>());
            var operation = _request["operation"]!.GetValue<string>();
            Log($"Beginning {operation} for {_request["expected_product"]} {_request["expected_version"]}.");
            return operation switch
            {
                "apply-portable" => ApplyPortable(),
                "apply-installer" => ApplyInstaller(),
                "repair" => Repair(),
                "rollback" => Rollback(),
                _ => throw new InvalidDataException("Updater operation is unsupported.")
            };
        }
        catch (Exception exception)
        {
            CleanupTemporaryExtraction();
            try { Fail(exception.Message); } catch { }
            try { Log($"FAIL: {exception.GetType().Name}: {exception.Message}"); } catch { }
            Console.Error.WriteLine($"PlayWorldUpdater failed: {exception.Message}");
            return 1;
        }
    }

    private static Dictionary<string, string> ParseArguments(string[] args)
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        for (var index = 0; index < args.Length; index++)
        {
            var value = args[index];
            if (value == "--relocated") { result["relocated"] = "1"; continue; }
            if (value == "--request" && index + 1 < args.Length) { result["request"] = args[++index]; continue; }
            throw new ArgumentException($"Unknown or incomplete updater argument: {value}");
        }
        if (!result.ContainsKey("request")) throw new ArgumentException("--request is required.");
        return result;
    }

    private static int RelocateAndLaunch()
    {
        var source = Environment.ProcessPath ?? throw new InvalidOperationException("Updater executable path is unavailable.");
        var root = Path.Combine(Path.GetTempPath(), "PlayWorldStudioUpdater", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        var target = Path.Combine(root, "PlayWorldUpdater.exe");
        File.Copy(source, target, true);
        var start = new ProcessStartInfo(target)
        {
            UseShellExecute = false,
            CreateNoWindow = true,
        };
        start.ArgumentList.Add("--request");
        start.ArgumentList.Add(_requestPath);
        start.ArgumentList.Add("--relocated");
        var relocatedProcess = Process.Start(start) ?? throw new InvalidOperationException("Relocated updater process could not start.");
        return 0;
    }

    private static void ValidateRequest(JsonObject request)
    {
        var required = new[] { "schema_version", "operation", "application_root", "artifact_path", "backup_root", "journal_path", "restart_executable", "expected_sha256", "expected_size", "expected_version", "expected_product", "parent_process_id", "install_mode", "created_at_unix" };
        foreach (var key in required) if (!request.ContainsKey(key)) throw new InvalidDataException($"Updater request field is missing: {key}");
        var allowed = new HashSet<string>(required, StringComparer.Ordinal) { "simulate_failure_stage" };
        foreach (var item in request)
        {
            if (!allowed.Contains(item.Key)) throw new InvalidDataException($"Updater request field is unsupported: {item.Key}");
        }
        if (request.ContainsKey("simulate_failure_stage") && Environment.GetEnvironmentVariable("PLAYWORLD_UPDATER_TEST_MODE") != "1") throw new InvalidDataException("Updater fault injection is permitted only in explicit test mode.");
        if (request["schema_version"]!.GetValue<int>() != 1) throw new InvalidDataException("Updater request schema is unsupported.");
        var operation = request["operation"]!.GetValue<string>();
        if (operation is not ("apply-portable" or "apply-installer" or "repair" or "rollback")) throw new InvalidDataException("Updater operation is invalid.");
        var installMode = request["install_mode"]!.GetValue<string>();
        if (installMode is not ("portable" or "installed")) throw new InvalidDataException("Updater install mode is invalid.");
        if (operation == "apply-portable" && installMode != "portable") throw new InvalidDataException("Portable update request has the wrong installation mode.");
        if (operation == "apply-installer" && installMode != "installed") throw new InvalidDataException("Installed update request has the wrong installation mode.");
        var applicationRoot = RequireFullPath(request["application_root"]!.GetValue<string>(), "Application root");
        var backupRoot = RequireFullPath(request["backup_root"]!.GetValue<string>(), "Backup root");
        var journalPath = RequireFullPath(request["journal_path"]!.GetValue<string>(), "Journal path");
        if (!Directory.Exists(applicationRoot)) throw new DirectoryNotFoundException("Application root does not exist.");
        RejectReparsePoint(applicationRoot);
        if (IsDescendant(backupRoot, applicationRoot) || IsDescendant(journalPath, applicationRoot)) throw new InvalidDataException("Backup and journal paths must remain outside the application directory.");
        var updateRoot = Path.GetDirectoryName(journalPath) ?? throw new InvalidDataException("Update journal directory is invalid.");
        if (!Directory.Exists(updateRoot)) throw new DirectoryNotFoundException("Bounded update-data root does not exist.");
        RejectReparsePoint(updateRoot);
        RejectReparsePoint(_requestPath);
        if (File.Exists(journalPath)) RejectReparsePoint(journalPath);
        if (Directory.Exists(backupRoot)) RejectReparsePoint(backupRoot);
        if (IsDescendant(applicationRoot, updateRoot) || IsDescendant(updateRoot, applicationRoot)) throw new InvalidDataException("Application and update-data roots must not overlap.");
        if (!IsDescendant(_requestPath, updateRoot) || !IsDescendant(backupRoot, updateRoot) || PathsEqual(backupRoot, updateRoot)) throw new InvalidDataException("Updater request, journal, and a distinct backup directory must remain inside the bounded update-data root.");
        if (PathsEqual(_requestPath, journalPath) || IsDescendant(_requestPath, backupRoot) || IsDescendant(journalPath, backupRoot)) throw new InvalidDataException("Request and journal files must remain outside the replaceable backup directory.");
        var createdAt = request["created_at_unix"]!.GetValue<long>();
        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        if (createdAt <= 0 || createdAt > now + 300 || createdAt < now - 21600) throw new InvalidDataException("Updater request is stale or has an invalid creation time.");
        var restartExecutable = request["restart_executable"]!.GetValue<string>();
        if (!string.IsNullOrWhiteSpace(restartExecutable))
        {
            restartExecutable = RequireFullPath(restartExecutable, "Restart executable");
            if (!IsDescendant(restartExecutable, applicationRoot) || !Path.GetFileName(restartExecutable).Equals("PlayWorld Studio.exe", StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Restart executable is outside the application-owned boundary.");
        }
        var artifact = request["artifact_path"]!.GetValue<string>();
        if (operation != "rollback")
        {
            artifact = RequireFullPath(artifact, "Artifact path");
            if (!File.Exists(artifact)) throw new FileNotFoundException("Verified update artifact is missing.");
            RejectReparsePoint(artifact);
            if (IsDescendant(artifact, applicationRoot) || !IsDescendant(artifact, updateRoot) || IsDescendant(artifact, backupRoot) || PathsEqual(artifact, journalPath) || PathsEqual(artifact, _requestPath)) throw new InvalidDataException("Update artifact must be staged inside the bounded update-data root, outside the live application and backup directories, and separate from request state.");
            if ((operation == "apply-portable" || (operation == "repair" && installMode == "portable")) && !artifact.EndsWith(".zip", StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Portable update request must reference a ZIP package.");
            if ((operation == "apply-installer" || (operation == "repair" && installMode == "installed")) && !artifact.EndsWith(".exe", StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Installed update request must reference an installer executable.");
            var expectedSize = request["expected_size"]!.GetValue<long>();
            if (expectedSize <= 0 || expectedSize > 8L * 1024 * 1024 * 1024) throw new InvalidDataException("Expected artifact size is outside accepted bounds.");
            var expectedHash = request["expected_sha256"]!.GetValue<string>();
            if (!IsLowerHex(expectedHash, 64)) throw new InvalidDataException("Expected SHA-256 is invalid.");
        }
        if (request["expected_product"]!.GetValue<string>() != "PlayWorld Studio") throw new InvalidDataException("Updater request targets a different product.");
        if (string.IsNullOrWhiteSpace(request["expected_version"]!.GetValue<string>())) throw new InvalidDataException("Expected version is missing.");
        if (request["parent_process_id"]!.GetValue<long>() <= 0) throw new InvalidDataException("Parent process identity is invalid.");
    }

    private static int ApplyPortable()
    {
        VerifyArtifact();
        MaybeInject("after-verification");
        var packageRoot = ExtractAndValidatePortable();
        try
        {
            BackupApplication();
            MaybeInject("after-backup");
            try
            {
                Transition("replacing", new JsonObject { ["recoverable"] = true });
                ReplaceApplication(packageRoot);
                MaybeInject("after-replacement");
                VerifyInstalledIdentity();
                FinalizeAndRestart();
                return 0;
            }
            catch
            {
                TryRestoreBackup();
                throw;
            }
        }
        finally
        {
            CleanupTemporaryExtraction();
        }
    }

    private static int ApplyInstaller()
    {
        VerifyArtifact();
        MaybeInject("after-verification");
        BackupApplication();
        MaybeInject("after-backup");
        try
        {
            Transition("installer_running", new JsonObject { ["recoverable"] = true });
            var installer = _request["artifact_path"]!.GetValue<string>();
            var appRoot = _request["application_root"]!.GetValue<string>();
            var start = new ProcessStartInfo(installer)
            {
                UseShellExecute = false,
                CreateNoWindow = true,
            };
            foreach (var argument in new[] { "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/SP-", $"/DIR={appRoot}" }) start.ArgumentList.Add(argument);
            MaybeInject("installed-handoff");
            using var process = Process.Start(start) ?? throw new InvalidOperationException("Installer could not start.");
            if (!process.WaitForExit((int)TimeSpan.FromMinutes(20).TotalMilliseconds)) { process.Kill(true); throw new TimeoutException("Installer timed out."); }
            if (process.ExitCode != 0) throw new InvalidOperationException($"Installer exited with code {process.ExitCode}.");
            var replacementInventory = CaptureApplicationInventory(appRoot);
            Transition("installer_running", new JsonObject { ["replacement_inventory"] = replacementInventory.DeepClone(), ["recoverable"] = true });
            var previousInventory = _journal["previous_inventory"] as JsonArray ?? new JsonArray();
            RemoveObsoleteOwnedFiles(appRoot, previousInventory, replacementInventory);
            VerifyInstalledIdentity();
            FinalizeAndRestart();
            return 0;
        }
        catch
        {
            TryRestoreBackup();
            throw;
        }
    }

    private static int Repair()
    {
        var artifact = _request["artifact_path"]!.GetValue<string>();
        return artifact.EndsWith(".zip", StringComparison.OrdinalIgnoreCase) ? ApplyPortable() : ApplyInstaller();
    }

    private static int Rollback()
    {
        Transition("rollback_pending", new JsonObject { ["recoverable"] = true });
        RestoreBackup();
        Transition("rolled_back", new JsonObject { ["outcome"] = "rolled_back", ["recoverable"] = false });
        RestartWithoutJournal();
        return 0;
    }

    private static void VerifyArtifact()
    {
        var artifact = _request["artifact_path"]!.GetValue<string>();
        var file = new FileInfo(artifact);
        if (file.Length != _request["expected_size"]!.GetValue<long>()) throw new InvalidDataException("Artifact byte count does not match the signed manifest.");
        var digest = Sha256File(artifact);
        if (!digest.Equals(_request["expected_sha256"]!.GetValue<string>(), StringComparison.Ordinal)) throw new InvalidDataException("Artifact SHA-256 does not match the signed manifest.");
        Transition("verified", new JsonObject { ["verified_size"] = file.Length, ["verified_sha256"] = digest });
    }

    private static string ExtractAndValidatePortable()
    {
        var requestDirectory = Path.GetDirectoryName(_requestPath)!;
        var extractRoot = Path.Combine(requestDirectory, "extract-" + Guid.NewGuid().ToString("N"));
        _temporaryExtractRoot = extractRoot;
        Directory.CreateDirectory(extractRoot);
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        long expanded = 0;
        using var archive = ZipFile.OpenRead(_request["artifact_path"]!.GetValue<string>());
        if (archive.Entries.Count <= 0 || archive.Entries.Count > MaxArchiveEntries) throw new InvalidDataException("Portable archive inventory is outside accepted bounds.");
        foreach (var entry in archive.Entries)
        {
            var relative = NormalizeArchivePath(entry.FullName);
            if (string.IsNullOrEmpty(relative)) continue;
            if (!seen.Add(relative)) throw new InvalidDataException("Portable archive contains duplicate normalized paths.");
            if (IsSymlink(entry)) throw new InvalidDataException("Portable archive contains a symbolic link.");
            expanded = checked(expanded + Math.Max(0, entry.Length));
            if (expanded > MaxExpandedBytes) throw new InvalidDataException("Portable archive expands beyond the accepted size limit.");
            var destination = Path.GetFullPath(Path.Combine(extractRoot, relative));
            if (!IsDescendant(destination, extractRoot)) throw new InvalidDataException("Portable archive attempts path traversal.");
            if (entry.FullName.EndsWith('/')) { Directory.CreateDirectory(destination); continue; }
            Directory.CreateDirectory(Path.GetDirectoryName(destination)!);
            entry.ExtractToFile(destination, true);
        }
        var candidates = new List<string> { extractRoot };
        candidates.AddRange(Directory.GetDirectories(extractRoot));
        var packageRoots = candidates.Where(path => File.Exists(Path.Combine(path, "PlayWorld Studio.exe")) && File.Exists(Path.Combine(path, "release_manifest.json"))).ToArray();
        if (packageRoots.Length != 1) throw new InvalidDataException("Portable archive does not contain exactly one valid PlayWorld Studio package root.");
        ValidatePackageManifest(packageRoots[0]);
        return packageRoots[0];
    }

    private static void ValidatePackageManifest(string packageRoot)
    {
        var manifestPath = Path.Combine(packageRoot, "release_manifest.json");
        var manifest = ReadObject(manifestPath, 16 * 1024 * 1024);
        if (manifest["product_name"]?.GetValue<string>() != _request["expected_product"]!.GetValue<string>()) throw new InvalidDataException("Portable package product identity is invalid.");
        if (manifest["version"]?.GetValue<string>() != _request["expected_version"]!.GetValue<string>()) throw new InvalidDataException("Portable package version identity is invalid.");
        if (manifest["platform"]?.GetValue<string>() != "Windows" || manifest["architecture"]?.GetValue<string>() != "x86_64") throw new InvalidDataException("Portable package target identity is invalid.");
        if (manifest["included_files"] is not JsonArray inventory || inventory.Count == 0) throw new InvalidDataException("Portable package inventory is missing.");
        var expected = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var node in inventory)
        {
            if (node is not JsonObject record) throw new InvalidDataException("Portable package inventory entry is invalid.");
            var relative = NormalizeRelativeFile(record["path"]?.GetValue<string>() ?? "");
            if (!expected.Add(relative)) throw new InvalidDataException("Portable package inventory contains duplicate paths.");
            var path = Path.GetFullPath(Path.Combine(packageRoot, relative));
            if (!IsDescendant(path, packageRoot) || !File.Exists(path)) throw new InvalidDataException($"Portable package inventory file is missing: {relative}");
            if (new FileInfo(path).Length != record["size"]?.GetValue<long>()) throw new InvalidDataException($"Portable package inventory size mismatch: {relative}");
            if (!Sha256File(path).Equals(record["sha256"]?.GetValue<string>(), StringComparison.Ordinal)) throw new InvalidDataException($"Portable package inventory hash mismatch: {relative}");
        }
        foreach (var file in Directory.EnumerateFiles(packageRoot, "*", SearchOption.AllDirectories))
        {
            RejectReparsePoint(file);
            var relative = NormalizeRelativeFile(Path.GetRelativePath(packageRoot, file));
            if (relative is "release_manifest.json" or "SHA256SUMS.txt") continue;
            if (!expected.Contains(relative)) throw new InvalidDataException($"Portable package contains an unexpected file: {relative}");
        }
    }

    private static void BackupApplication()
    {
        var appRoot = _request["application_root"]!.GetValue<string>();
        var backupRoot = _request["backup_root"]!.GetValue<string>();
        if (Directory.Exists(backupRoot)) Directory.Delete(backupRoot, true);
        Directory.CreateDirectory(backupRoot);
        Transition("backing_up", new JsonObject { ["backup_root"] = backupRoot, ["application_root"] = appRoot, ["recoverable"] = true });
        var inventory = CaptureApplicationInventory(appRoot);
        foreach (var node in inventory)
        {
            var record = node as JsonObject ?? throw new InvalidDataException("Application inventory entry is invalid.");
            var relative = NormalizeRelativeFile(record["path"]?.GetValue<string>() ?? "");
            var source = Path.Combine(appRoot, relative);
            var target = Path.Combine(backupRoot, relative);
            Directory.CreateDirectory(Path.GetDirectoryName(target)!);
            File.Copy(source, target, true);
        }
        var manifest = new JsonObject { ["schema_version"] = 1, ["product_name"] = "PlayWorld Studio", ["created_at_unix"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds(), ["included_files"] = inventory.DeepClone() };
        AtomicWrite(Path.Combine(backupRoot, "backup_manifest.json"), manifest);
        Transition("backing_up", new JsonObject { ["backup_root"] = backupRoot, ["previous_inventory"] = inventory.DeepClone(), ["recoverable"] = true });
    }

    private static void ReplaceApplication(string packageRoot)
    {
        var appRoot = _request["application_root"]!.GetValue<string>();
        var replacementInventory = CaptureDirectoryInventory(packageRoot);
        var previousInventory = _journal["previous_inventory"] as JsonArray ?? new JsonArray();
        RemoveOwnedFiles(appRoot, previousInventory);
        Transition("replacing", new JsonObject { ["replacement_inventory"] = replacementInventory.DeepClone(), ["recoverable"] = true });
        var completed = new JsonArray();
        foreach (var node in replacementInventory)
        {
            var record = node as JsonObject ?? throw new InvalidDataException("Replacement inventory entry is invalid.");
            var relative = NormalizeRelativeFile(record["path"]?.GetValue<string>() ?? "");
            var source = Path.Combine(packageRoot, relative);
            var target = Path.Combine(appRoot, relative);
            Directory.CreateDirectory(Path.GetDirectoryName(target)!);
            File.Copy(source, target, true);
            completed.Add(relative);
            Transition("replacing", new JsonObject { ["completed_paths"] = completed.DeepClone(), ["recoverable"] = true });
            if (completed.Count == 1) MaybeInject("during-replacement");
        }
    }

    private static void RestoreBackup()
    {
        var appRoot = _request["application_root"]!.GetValue<string>();
        var backupRoot = _request["backup_root"]!.GetValue<string>();
        var manifestPath = Path.Combine(backupRoot, "backup_manifest.json");
        if (!File.Exists(manifestPath)) throw new InvalidDataException("Rollback backup manifest is missing.");
        var manifest = ReadObject(manifestPath, 16 * 1024 * 1024);
        if (manifest["product_name"]?.GetValue<string>() != "PlayWorld Studio" || manifest["included_files"] is not JsonArray inventory) throw new InvalidDataException("Rollback backup identity is invalid.");
        foreach (var node in inventory)
        {
            var record = node as JsonObject ?? throw new InvalidDataException("Rollback backup inventory entry is invalid.");
            var relative = NormalizeRelativeFile(record["path"]?.GetValue<string>() ?? "");
            var source = Path.Combine(backupRoot, relative);
            if (!File.Exists(source) || new FileInfo(source).Length != record["size"]?.GetValue<long>() || !Sha256File(source).Equals(record["sha256"]?.GetValue<string>(), StringComparison.Ordinal)) throw new InvalidDataException($"Rollback backup verification failed: {relative}");
        }
        var replacementInventory = _journal["replacement_inventory"] as JsonArray;
        if (replacementInventory is null || replacementInventory.Count == 0)
        {
            replacementInventory = (_journal["previous_inventory"] as JsonArray)?.DeepClone() as JsonArray ?? new JsonArray();
            var currentManifest = Path.Combine(appRoot, "release_manifest.json");
            if (File.Exists(currentManifest))
            {
                foreach (var node in CaptureApplicationInventory(appRoot)) replacementInventory.Add(node?.DeepClone());
            }
        }
        RemoveOwnedFiles(appRoot, replacementInventory);
        foreach (var node in inventory)
        {
            var record = (JsonObject)node!;
            var relative = NormalizeRelativeFile(record["path"]!.GetValue<string>());
            var target = Path.Combine(appRoot, relative);
            Directory.CreateDirectory(Path.GetDirectoryName(target)!);
            File.Copy(Path.Combine(backupRoot, relative), target, true);
        }
    }

    private static JsonArray CaptureApplicationInventory(string appRoot)
    {
        var manifestPath = Path.Combine(appRoot, "release_manifest.json");
        if (!File.Exists(manifestPath)) throw new InvalidDataException("Current application release manifest is missing; application-owned files cannot be identified safely.");
        var manifest = ReadObject(manifestPath, 16 * 1024 * 1024);
        if (manifest["product_name"]?.GetValue<string>() != "PlayWorld Studio" || manifest["included_files"] is not JsonArray declared) throw new InvalidDataException("Current application release manifest identity is invalid.");
        var paths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var node in declared)
        {
            var record = node as JsonObject ?? throw new InvalidDataException("Current application inventory entry is invalid.");
            paths.Add(NormalizeRelativeFile(record["path"]?.GetValue<string>() ?? ""));
        }
        foreach (var special in new[] { "release_manifest.json", "SHA256SUMS.txt" }) if (File.Exists(Path.Combine(appRoot, special))) paths.Add(special);
        foreach (var file in Directory.EnumerateFiles(appRoot, "unins*", SearchOption.TopDirectoryOnly)) paths.Add(NormalizeRelativeFile(Path.GetRelativePath(appRoot, file)));
        var inventory = new JsonArray();
        foreach (var relative in paths.OrderBy(value => value, StringComparer.OrdinalIgnoreCase))
        {
            var path = Path.Combine(appRoot, relative);
            if (!File.Exists(path)) continue;
            RejectReparsePoint(path);
            inventory.Add(new JsonObject { ["path"] = relative, ["size"] = new FileInfo(path).Length, ["sha256"] = Sha256File(path) });
        }
        if (inventory.Count == 0) throw new InvalidDataException("Current application has no verifiable application-owned files.");
        return inventory;
    }

    private static JsonArray CaptureDirectoryInventory(string root)
    {
        var inventory = new JsonArray();
        foreach (var file in Directory.EnumerateFiles(root, "*", SearchOption.AllDirectories).OrderBy(value => value, StringComparer.OrdinalIgnoreCase))
        {
            RejectReparsePoint(file);
            var relative = NormalizeRelativeFile(Path.GetRelativePath(root, file));
            inventory.Add(new JsonObject { ["path"] = relative, ["size"] = new FileInfo(file).Length, ["sha256"] = Sha256File(file) });
        }
        if (inventory.Count == 0) throw new InvalidDataException("Replacement package inventory is empty.");
        return inventory;
    }

    private static void RemoveOwnedFiles(string appRoot, JsonArray inventory)
    {
        var parents = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var node in inventory)
        {
            var record = node as JsonObject ?? throw new InvalidDataException("Application-owned inventory entry is invalid.");
            var relative = NormalizeRelativeFile(record["path"]?.GetValue<string>() ?? "");
            var target = Path.GetFullPath(Path.Combine(appRoot, relative));
            if (!IsDescendant(target, appRoot)) throw new InvalidDataException("Application-owned path resolves outside the application directory.");
            if (!File.Exists(target)) continue;
            RejectReparsePoint(target);
            File.SetAttributes(target, FileAttributes.Normal);
            File.Delete(target);
            var parent = Path.GetDirectoryName(target);
            if (!string.IsNullOrEmpty(parent)) parents.Add(parent);
        }
        foreach (var directory in parents.OrderByDescending(value => value.Length))
        {
            var current = directory;
            while (IsDescendant(current, appRoot) && !current.Equals(appRoot, StringComparison.OrdinalIgnoreCase))
            {
                if (!Directory.Exists(current) || Directory.EnumerateFileSystemEntries(current).Any()) break;
                Directory.Delete(current);
                current = Path.GetDirectoryName(current) ?? appRoot;
            }
        }
    }

    private static void RemoveObsoleteOwnedFiles(string appRoot, JsonArray previousInventory, JsonArray replacementInventory)
    {
        var replacementPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var node in replacementInventory)
        {
            var record = node as JsonObject ?? throw new InvalidDataException("Replacement inventory entry is invalid.");
            replacementPaths.Add(NormalizeRelativeFile(record["path"]?.GetValue<string>() ?? ""));
        }
        var obsolete = new JsonArray();
        foreach (var node in previousInventory)
        {
            var record = node as JsonObject ?? throw new InvalidDataException("Previous inventory entry is invalid.");
            var relative = NormalizeRelativeFile(record["path"]?.GetValue<string>() ?? "");
            if (!replacementPaths.Contains(relative)) obsolete.Add(record.DeepClone());
        }
        RemoveOwnedFiles(appRoot, obsolete);
    }

    private static void TryRestoreBackup()
    {
        try
        {
            RestoreBackup();
            Transition("rolled_back", new JsonObject { ["outcome"] = "rolled_back_after_failure", ["recoverable"] = false });
        }
        catch (Exception rollbackError)
        {
            Log($"Rollback failed: {rollbackError.Message}");
            Fail("Application update failed and automatic rollback also failed. Use the recovery backup.");
        }
    }

    private static void VerifyInstalledIdentity()
    {
        var appRoot = _request["application_root"]!.GetValue<string>();
        var manifest = ReadObject(Path.Combine(appRoot, "release_manifest.json"), 16 * 1024 * 1024);
        if (manifest["product_name"]?.GetValue<string>() != _request["expected_product"]!.GetValue<string>() || manifest["version"]?.GetValue<string>() != _request["expected_version"]!.GetValue<string>()) throw new InvalidDataException("Updated application identity does not match the signed request.");
        if (!File.Exists(Path.Combine(appRoot, "PlayWorld Studio.exe"))) throw new InvalidDataException("Updated creator executable is missing.");
    }

    private static void LoadJournal()
    {
        var path = _request["journal_path"]!.GetValue<string>();
        if (File.Exists(path))
        {
            _journal = ReadObject(path, 4 * 1024 * 1024);
            ValidateJournal(_journal);
            return;
        }
        var requestOperation = _request["operation"]!.GetValue<string>();
        var journalOperation = requestOperation switch
        {
            "apply-portable" => "portable_update",
            "apply-installer" => "installed_update",
            "repair" => "repair",
            "rollback" => "rollback",
            _ => throw new InvalidDataException("Updater journal operation is invalid.")
        };
        _journal = new JsonObject
        {
            ["schema_version"] = 1,
            ["operation_id"] = Guid.NewGuid().ToString("N"),
            ["operation"] = journalOperation,
            ["stage"] = "handoff",
            ["created_at_unix"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
            ["updated_at_unix"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
            ["outcome"] = "in_progress",
            ["artifact"] = new JsonObject(),
            ["previous_inventory"] = new JsonArray(),
            ["replacement_inventory"] = new JsonArray(),
            ["completed_paths"] = new JsonArray(),
            ["errors"] = new JsonArray(),
            ["metadata"] = new JsonObject()
        };
    }

    private static void ValidateJournal(JsonObject journal)
    {
        var required = new[] { "schema_version", "operation_id", "operation", "stage", "created_at_unix", "updated_at_unix", "outcome", "artifact", "previous_inventory", "replacement_inventory", "completed_paths", "errors", "metadata" };
        foreach (var key in required) if (!journal.ContainsKey(key)) throw new InvalidDataException($"Update journal field is missing: {key}");
        if (journal["schema_version"]!.GetValue<int>() != 1) throw new InvalidDataException("Update journal schema is unsupported.");
        if (journal["operation"]!.GetValue<string>() is not ("portable_update" or "installed_update" or "repair" or "rollback")) throw new InvalidDataException("Update journal operation is invalid.");
        if (!JournalStages.Contains(journal["stage"]!.GetValue<string>())) throw new InvalidDataException("Update journal stage is invalid.");
        foreach (var key in new[] { "previous_inventory", "replacement_inventory", "completed_paths", "errors" })
            if (journal[key] is not JsonArray) throw new InvalidDataException($"Update journal collection is invalid: {key}");
        foreach (var node in journal["completed_paths"]!.AsArray()) NormalizeRelativeFile(node?.GetValue<string>() ?? "");
        foreach (var key in new[] { "previous_inventory", "replacement_inventory" })
        {
            foreach (var node in journal[key]!.AsArray())
            {
                if (node is not JsonObject record) throw new InvalidDataException($"Update journal inventory entry is invalid: {key}");
                NormalizeRelativeFile(record["path"]?.GetValue<string>() ?? "");
            }
        }
    }

    private static void Transition(string stage, JsonObject? patch = null)
    {
        _journal["stage"] = stage;
        _journal["updated_at_unix"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        if (patch is not null) foreach (var item in patch) _journal[item.Key] = item.Value?.DeepClone();
        AtomicWrite(_request["journal_path"]!.GetValue<string>(), _journal);
        Log($"Stage: {stage}");
    }

    private static void Complete()
    {
        Transition("completed", new JsonObject { ["outcome"] = "success", ["recoverable"] = false, ["completed_at_unix"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds() });
    }

    private static void Fail(string message)
    {
        if (_journal.Count == 0 || !_request.ContainsKey("journal_path")) return;
        if ((_journal["stage"]?.GetValue<string>() ?? "") == "rolled_back") return;
        var errors = _journal["errors"] as JsonArray ?? new JsonArray();
        errors.Add(new JsonObject { ["at_unix"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds(), ["message"] = message.Length > 1024 ? message[..1024] : message });
        Transition("failed", new JsonObject { ["outcome"] = "failed", ["recoverable"] = true, ["errors"] = errors });
    }

    private static void RestartWithoutJournal()
    {
        var executable = _request["restart_executable"]!.GetValue<string>();
        if (string.IsNullOrWhiteSpace(executable)) return;
        executable = RequireFullPath(executable, "Restart executable");
        if (!File.Exists(executable)) executable = Path.Combine(_request["application_root"]!.GetValue<string>(), "PlayWorld Studio.exe");
        if (File.Exists(executable)) Process.Start(new ProcessStartInfo(executable) { UseShellExecute = true });
    }

    private static void FinalizeAndRestart(bool markCompleted = true)
    {
        var executable = _request["restart_executable"]!.GetValue<string>();
        if (string.IsNullOrWhiteSpace(executable))
        {
            if (markCompleted) Complete();
            return;
        }
        executable = RequireFullPath(executable, "Restart executable");
        if (!File.Exists(executable)) executable = Path.Combine(_request["application_root"]!.GetValue<string>(), "PlayWorld Studio.exe");
        if (!File.Exists(executable)) throw new FileNotFoundException("Restart executable is missing after update.");
        Transition("restart_pending", new JsonObject { ["restart_executable"] = executable });
        if (markCompleted) Complete();
        var restartedProcess = Process.Start(new ProcessStartInfo(executable) { UseShellExecute = true }) ?? throw new InvalidOperationException("Updated application could not restart.");
    }

    private static void MaybeInject(string stage)
    {
        if (Environment.GetEnvironmentVariable("PLAYWORLD_UPDATER_TEST_MODE") != "1") return;
        var requested = _request["simulate_failure_stage"]?.GetValue<string>() ?? "";
        if (requested.Equals(stage, StringComparison.Ordinal)) throw new InvalidOperationException($"Intentional updater fault injection at {stage}.");
    }

    private static void WaitForParent(int processId)
    {
        try
        {
            using var process = Process.GetProcessById(processId);
            if (!process.WaitForExit((int)TimeSpan.FromMinutes(2).TotalMilliseconds)) throw new TimeoutException("Creator process did not exit for update handoff.");
        }
        catch (ArgumentException) { }
    }

    private static string NormalizeArchivePath(string value)
    {
        var normalized = value.Replace('\\', '/').TrimStart('/');
        if (string.IsNullOrWhiteSpace(normalized)) return "";
        if (Path.IsPathRooted(value) || normalized.Contains(':')) throw new InvalidDataException("Archive path is absolute or drive-qualified.");
        var parts = normalized.Split('/', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Any(part => part is "." or "..")) throw new InvalidDataException("Archive path contains traversal segments.");
        return string.Join(Path.DirectorySeparatorChar, parts);
    }

    private static string NormalizeRelativeFile(string value)
    {
        var normalized = value.Replace('\\', '/');
        if (string.IsNullOrWhiteSpace(normalized) || normalized.StartsWith('/') || normalized.Contains(':')) throw new InvalidDataException("Inventory path is unsafe.");
        var parts = normalized.Split('/', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Any(part => part is "." or "..")) throw new InvalidDataException("Inventory path contains traversal segments.");
        if (parts.Length > 0 && ProtectedTopLevel.Contains(parts[0])) throw new InvalidDataException("Protected user-data path is forbidden in the application replacement inventory.");
        return string.Join(Path.DirectorySeparatorChar, parts);
    }

    private static bool IsSymlink(ZipArchiveEntry entry)
    {
        var unixType = (entry.ExternalAttributes >> 16) & 0xF000;
        return unixType == 0xA000;
    }

    private static void RejectReparsePoint(string path)
    {
        if ((File.GetAttributes(path) & FileAttributes.ReparsePoint) != 0) throw new InvalidDataException($"Reparse point is not permitted in update inventory: {Path.GetFileName(path)}");
    }

    private static void CleanupTemporaryExtraction()
    {
        if (string.IsNullOrWhiteSpace(_temporaryExtractRoot)) return;
        try
        {
            if (Directory.Exists(_temporaryExtractRoot)) Directory.Delete(_temporaryExtractRoot, true);
        }
        catch (Exception cleanupError)
        {
            Log($"Temporary extraction cleanup warning: {cleanupError.Message}");
        }
        finally
        {
            _temporaryExtractRoot = "";
        }
    }

    private static bool PathsEqual(string left, string right)
    {
        return Path.GetFullPath(left).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
            .Equals(Path.GetFullPath(right).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar), StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsDescendant(string candidate, string root)
    {
        var fullCandidate = Path.GetFullPath(candidate).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        var fullRoot = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        return fullCandidate.Equals(fullRoot, StringComparison.OrdinalIgnoreCase) || fullCandidate.StartsWith(fullRoot + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase);
    }

    private static string RequireFullPath(string? value, string name)
    {
        if (string.IsNullOrWhiteSpace(value) || !Path.IsPathFullyQualified(value)) throw new InvalidDataException($"{name} must be an absolute path.");
        return Path.GetFullPath(value);
    }

    private static bool IsLowerHex(string value, int length) => value.Length == length && value.All(character => character is >= '0' and <= '9' or >= 'a' and <= 'f');

    private static string Sha256File(string path)
    {
        using var stream = File.OpenRead(path);
        return Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant();
    }

    private static JsonObject ReadObject(string path, long maximumBytes)
    {
        var info = new FileInfo(path);
        if (!info.Exists || info.Length <= 0 || info.Length > maximumBytes) throw new InvalidDataException("JSON file size is outside accepted bounds.");
        var node = JsonNode.Parse(File.ReadAllText(path, Encoding.UTF8), documentOptions: new JsonDocumentOptions { CommentHandling = JsonCommentHandling.Disallow, AllowTrailingCommas = false });
        return node as JsonObject ?? throw new InvalidDataException("JSON document is not an object.");
    }

    private static void AtomicWrite(string path, JsonObject value)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        var temporary = path + ".phase19-" + Guid.NewGuid().ToString("N") + ".tmp";
        File.WriteAllText(temporary, value.ToJsonString(new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, new UTF8Encoding(false));
        File.Move(temporary, path, true);
    }

    private static void Log(string message)
    {
        if (string.IsNullOrWhiteSpace(_logPath)) return;
        Directory.CreateDirectory(Path.GetDirectoryName(_logPath)!);
        File.AppendAllText(_logPath, $"{DateTimeOffset.UtcNow:O} {message}{Environment.NewLine}", new UTF8Encoding(false));
    }
}
