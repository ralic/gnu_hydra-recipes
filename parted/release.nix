/* Continuous integration of GNU with Hydra/Nix.
   Copyright (C) 2010  Ludovic Courtès <ludo@gnu.org>
   Copyright (C) 2010  Rob Vermaas <rob.vermaas@gmail.com>

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

{ nixpkgs ? { outPath = ../../nixpkgs; }
, gnulib ? { outPath = ../../gnulib; }
, partedSrc ? { outPath = ../../parted; } }:

let
  pkgs = import nixpkgs {};

  meta = {
    description = "GNU Parted, a tool to create, destroy, resize, check, and copy partitions";

    longDescription = ''
      GNU Parted is an industrial-strength package for creating, destroying,
      resizing, checking and copying partitions, and the file systems on
      them.  This is useful for creating space for new operating systems,
      reorganising disk usage, copying data on hard disks and disk imaging.

      It contains a library, libparted, and a command-line frontend, parted,
      which also serves as a sample implementation and script backend.
    '';

    homepage = http://www.gnu.org/software/parted/;
    license = "GPLv3+";

    maintainers = [
    ];

    # GNU Parted requires libuuid, which is part of util-linux-ng.
    platforms = pkgs.stdenv.lib.platforms.linux;
  };

  jobs = {
    tarball =
      with pkgs;
      releaseTools.sourceTarball {
        name = "parted";
        src = partedSrc;
        buildInputs =
          [ git xz gettext texinfo automake111x perl rsync gperf man cvs
            devicemapper libuuid gettext readline pkgconfig # utillinuxng
          ];
        autoconfPhase =
          '' git config submodule.gnulib.url "${gnulib}"
             ./bootstrap --gnulib-srcdir="${gnulib}" --skip-po
          '';
        inherit meta;
      };

    build =
      { system ? builtins.currentSystem
      , tarball ? jobs.tarball }:

      let pkgs = import nixpkgs { inherit system; };
      in
        with pkgs;
        pkgs.releaseTools.nixBuild {
          name = "parted";
          src = tarball;
          failureHook =
            '' if [ -f tests/test-suite.log ]
               then
                   header 'tests/test-suite.log'
                   echo
                   echo "build failed, dumping test log..."
                   cat tests/test-suite.log
                   stopNest
               fi
            '';
          buildInputs = [devicemapper libuuid gettext readline]; 

          configureFlags = "--with-readline";

          inherit meta;
        };

    coverage =
      { tarball ? jobs.tarball }:

      let pkgs = import nixpkgs {};
      in
        pkgs.releaseTools.coverageAnalysis {
          name = "parted-coverage";
          src = tarball;
        };
  };
in
  jobs