{
  lib,
  buildDartApplication,
  fetchFromGitHub,
}:

buildDartApplication rec {
  pname = "flutter-inspector-mcp-server";
  version = "0.1.0-unstable-2025-10-13";

  src = fetchFromGitHub {
    owner = "Arenukvern";
    repo = "mcp_flutter";
    rev = "16cb6ce69d16e287c30c8a4a8be64177bfa94719";
    hash = "sha256-hC2OZENdDAK2npAUqId8n4nlkc9jtTeNsH3PYxv9bdo=";
  };

  sourceRoot = "${src.name}/mcp_server_dart";

  pubspecLock = lib.importJSON ./mcp-flutter-pubspec.lock.json;

  meta = with lib; {
    description = "MCP server for Flutter Inspector - exposes Flutter debugging tools to AI models via Dart VM service";
    homepage = "https://github.com/Arenukvern/mcp_flutter";
    license = licenses.mit;
    platforms = platforms.all;
    mainProgram = "flutter_inspector_mcp_server";
  };
}
