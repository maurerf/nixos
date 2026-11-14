{ pkgs }:

let
  # The patched files were compared byte-for-byte with the
  # lib layer in the pinned amd64 image, not merely with a mutable release tag.
  source = pkgs.fetchFromGitHub {
    owner = "orangecoding";
    repo = "fredy";
    rev = "9f6551ee74249924c57e671a36658e890c52d9f2";
    hash = "sha256-eovSDnVMw60GtMM4V8DqBnLGZIEejN+FzJBFUOcetGQ=";
  };
  patched = pkgs.runCommand "fredy-29.2.1-pagination-source" {
    nativeBuildInputs = [ pkgs.patch pkgs.nodejs ];
  } ''
    cp -R ${source} source
    chmod -R u+w source
    cd source
    patch --fuzz=0 -p1 < ${./pagination.patch}
    patch --fuzz=0 -p1 < ${./browser.patch}
    cp ${./pagination.js} lib/services/searchPagination.js
    mkdir tests-local
    cp ${./pagination.js} tests-local/pagination.js
    cp ${./pagination.test.mjs} tests-local/pagination.test.mjs
    FREDY_SOURCE="$PWD" node --experimental-vm-modules --test tests-local/pagination.test.mjs
    mkdir -p "$out/fredy/lib/services/immoscout" "$out/fredy/lib/services/immowelt" "$out/fredy/lib/services/extractor"
    cp lib/services/searchPagination.js "$out/fredy/lib/services/"
    cp lib/services/immoscout/mobileApi.js "$out/fredy/lib/services/immoscout/"
    cp lib/services/immowelt/immoweltBff.js "$out/fredy/lib/services/immowelt/"
    cp lib/services/extractor/puppeteerExtractor.js "$out/fredy/lib/services/extractor/"
  '';
  base = pkgs.dockerTools.pullImage {
    imageName = "ghcr.io/orangecoding/fredy";
    imageDigest = "sha256:1be69e57027924abba16a0d06f37697ae883322002e0fd2d2325f8ef459612cc";
    sha256 = "sha256-/JgufSuk9dZPenHsA1BkO4o36QEVz1g+ezqUMYNbAvw=";
    os = "linux";
    arch = "amd64";
    finalImageName = "fredy-base";
    finalImageTag = "29.2.1";
  };
in
pkgs.dockerTools.buildImage {
  name = "fredy-pagination";
  # The default tag derives from the Nix output hash: changed patches cannot
  # accidentally reuse an old Podman tag. imageFile supplies the local archive.
  architecture = "amd64";
  fromImage = base;
  copyToRoot = patched;
  config = {
    # buildImage inherits the base environment, but not its other config fields.
    Entrypoint = [ "/usr/bin/tini" "-g" "--" ];
    Cmd = [ "node" "index.js" ];
    WorkingDir = "/fredy";
    ExposedPorts."9998/tcp" = { };
    Volumes = { "/conf" = { }; "/db" = { }; };
    Labels = {
      "org.opencontainers.image.version" = "29.2.1-pagination-4";
      "org.opencontainers.image.base.digest" = "sha256:1be69e57027924abba16a0d06f37697ae883322002e0fd2d2325f8ef459612cc";
    };
    # The service also sets an explicit Podman health check.
    Healthcheck = {
      Test = [ "CMD-SHELL" "curl -f http://localhost:9998/ || exit 1" ];
      Interval = 30000000000;
      Timeout = 10000000000;
      StartPeriod = 30000000000;
      Retries = 3;
    };
  };
}
