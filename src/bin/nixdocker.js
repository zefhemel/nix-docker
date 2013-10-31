#!/usr/bin/env node

var optimist = require("optimist");
var fs = require("fs");
var path = require("path");

var rootPath = path.resolve(fs.realpathSync(process.argv[1]), "../..");

console.log("Root path", rootPath);

var spawn = require('child_process').spawn;
var execFile = require('child_process').execFile;

function pipeRun(cmd, args, callback) {
    var command = spawn(cmd, args);
    command.stdout.pipe(process.stdout);
    command.stderr.pipe(process.stderr);

    command.on('close', function(code) {
        callback(code);
    });
}

function build(nix, configPath, callback) {
    var nixBuild = spawn('nix-build', [nix, '-I', 'configuration=' + configPath]);
    var nixPath;

    nixBuild.stdout.on('data', function(data) {
        nixPath = data.toString("ascii");
    });
    nixBuild.stderr.pipe(process.stderr);

    nixBuild.on('close', function(code) {
        if (code === 0) {
            callback(null, nixPath.trim());
        } else {
            callback(code);
        }
    });
}

build(rootPath + "/docker.nix", "configuration.nix", function(err, startPath) {
    build(rootPath + "/dockerfile.nix", "configuration.nix", function(err, dockerFilePath) {
        execFile("nix-store", ["-qR", startPath], {}, function(err, stdout) {
            if (err) {
                return console.error(err);
            }
            var paths = stdout.split("\n");
            var dockerFile = fs.readFileSync(dockerFilePath + "/Dockerfile").toString("ascii");
            var dockerLines = [];
            
            if(!fs.existsSync("nix_symlink")) {
                fs.symlinkSync("/nix", "nix_symlink");
            }
            
            paths.forEach(function(path) {
                if (path) {
                    dockerLines.push("ADD " + "nix_symlink" + path.substring("/nix".length) + " " + path);
                }
            });
            dockerLines.push("CMD " + startPath + "/bin/start");
            fs.writeFileSync("Dockerfile", dockerFile.replace("<<BODY>>", dockerLines.join("\n")));
            pipeRun("docker", ["build", "-t", "test", "."], function(code) {
                fs.unlinkSync("nix_symlink");
                process.exit(code);
            });
        });
    });
});