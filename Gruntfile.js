module.exports = function(grunt) {

  grunt.file.defaultEncoding = 'utf8';
  grunt.file.preserveBOM = true;

  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-cssmin');

  var pkg = grunt.file.readJSON('package.json');
  var dancer = grunt.file.readYAML('config.yml');

  var js_build_path      = dancer.assets.js['build_folder'] + '/' + dancer.assets.js['build_file'];
  var js_build_min_path  = dancer.assets.js['build_folder'] + '/' + dancer.assets.js['build_file_min'];
  var css_build_path     = dancer.assets.css['build_folder'] + '/' + dancer.assets.css['build_file'];
  var css_build_min_path = dancer.assets.css['build_folder'] + '/' + dancer.assets.css['build_file_min'];

  grunt.initConfig({

    pkg: pkg,

    clean: {
      build: [dancer.assets.js['build_folder'], dancer.assets.css['build_folder']],
    },

    concat: {
      js: {
        src: dancer.assets.js.files,
        dest: js_build_path
      },
      css: {
        src: dancer.assets.css.files,
        dest: css_build_path
      }
    },

    uglify: {
      js: {
        options: {
          banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n',
          report: 'min'
        },
        src: js_build_path,
        dest: js_build_min_path
      }
    },

    cssmin: {
      css: {
        options: {
          banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n',
          report: 'min'
        },
        src: css_build_path,
        dest: css_build_min_path
      }
    }

  });

  grunt.registerTask('default', ['clean','concat','uglify','cssmin']);

};
