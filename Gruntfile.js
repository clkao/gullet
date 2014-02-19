grunt = require('grunt');
grunt.loadNpmTasks('grunt-node-webkit-builder');

grunt.initConfig({
  nodewebkit: {
    options: {
        build_dir: './dist', // Where the build version of my node-webkit app is saved
        mac: true, // We want to build it for mac
        win: true, // We want to build it for win
        linux32: false, // We don't need linux32
        linux64: false // We don't need linux64
    },
    src: ['./_public/**/*'] // Your node-wekit app
  }
})
