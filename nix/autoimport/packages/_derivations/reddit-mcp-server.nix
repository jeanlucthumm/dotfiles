{
  lib,
  buildNpmPackage,
  fetchurl,
}:
buildNpmPackage (finalAttrs: {
  pname = "reddit-mcp-server";
  version = "1.4.8";

  # Use the published npm tarball rather than the GitHub source: it ships the
  # prebuilt dist/, so we avoid the pnpm/rolldown/esbuild build toolchain (which
  # gets SIGKILL'd in the darwin build sandbox) and only need the runtime deps.
  src = fetchurl {
    url = "https://registry.npmjs.org/reddit-mcp-server/-/reddit-mcp-server-${finalAttrs.version}.tgz";
    hash = "sha256-dgSZQhih7q1tTphi9Pj8Xzc5aUSuTUALGo6a49UPg5s=";
  };

  # The npm tarball has no lockfile, so vendor a generated prod-only
  # package-lock.json. Regenerate with:
  #   npm install --package-lock-only --omit=dev   (in the unpacked tarball)
  postPatch = ''
    cp ${./reddit-mcp-server-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-ewYiJ1rmMjPCzQ7LJ5UWN1jqrcakcA2fZxn3UCzruAs=";

  # dist/ is already built and shipped in the tarball; nothing to compile.
  dontNpmBuild = true;

  meta = {
    description = "MCP server for Reddit with full read and write operations";
    homepage = "https://github.com/jordanburke/reddit-mcp-server";
    changelog = "https://github.com/jordanburke/reddit-mcp-server/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "reddit-mcp-server";
    platforms = lib.platforms.all;
  };
})
