'use strict';

const gulp = require('gulp'),
      del = require('del'),
      autoprefixer = require('gulp-autoprefixer'),
      gulpIf = require('gulp-if'),
      uglify = require('gulp-uglify'),
      useref = require('gulp-useref'),
      jshint = require('gulp-jshint'),
      cssmin = require('gulp-cssmin'),
      concat = require('gulp-concat'),
      htmlmin = require('gulp-minify-html-2'),
      templateCache = require('gulp-angular-templatecache'),
      replace = require('gulp-replace'),
      through = require('through2'),
      traceur = require('gulp-traceur-compiler'),
      debug = require('gulp-debug'),
      gulpIgnore = require('gulp-ignore'),
      fs = require("fs"),
      p = require('./package.json');

gulp.task('lint', function () {
    return gulp.src(['csp/src/app.js','csp/src/{controller,services}/*.js'])
        .pipe(jshint())
        .pipe(jshint.reporter('default'));
});

gulp.task('minify:js', function () {
    return gulp.src('./csp/index.html')
        .pipe(useref())
        .pipe(gulpIf("*.js",replace('"{{package.json.version}}"', '"' + p.version + '"')))
        .pipe(gulpIf("*.js",traceur()))
        .pipe(gulpIf("*.js",uglify()))
        .pipe(gulpIf("*.html",htmlmin({empty: false})))
        .pipe(gulp.dest('build'));
});

gulp.task('minify:css', function () {
    return gulp.src('csp/css/custom.css')
        .pipe(autoprefixer())
        .pipe(cssmin())
        .pipe(gulp.dest('build/css'))
});

gulp.task('minify:template', function () {
    return gulp.src('csp/src/view/*.html')
        .pipe(htmlmin({empty: false}))
        .pipe(templateCache({root:"src/view"}))
        .pipe(gulp.dest('build/src/'))
});

gulp.task('concat-with-templates', function () {
    return gulp.src(['build/src/app.js', 'build/src/templates.js'])
        .pipe(concat('app.js'))
        .pipe(gulp.dest('build/src'))
});

gulp.task('copy:csslibs', function () {
    return gulp.src('csp/css/*.min.css')
        .pipe(gulp.dest('build/css'));
});

gulp.task('copy:jslibs', function () {
    return gulp.src('csp/src/lib/*.*')
        .pipe(gulp.dest('build/src/lib'))
});

gulp.task('copy:fonts', function () {
    return gulp.src('csp/fonts/*.*')
        .pipe(gulp.dest('build/fonts'))
});

gulp.task('cleanup:before-build',function () {
    return new Promise((resolve,reject)=>{
        del('build');
        resolve();
    });
});

gulp.task('cleanup:after-build',function () {
    return new Promise((resolve,reject)=>{
        del('build/src/templates.js');
        resolve();
    });
});

let FILE_LISTCSP;
gulp.task('enum-files:csp', function() {
    FILE_LISTCSP = [];
    return gulp.src('build/**/*.*',{read: false})
        .pipe(gulpIgnore.exclude('*.xml'))
        .pipe(through.obj(function (chunk, enc, cb) {
            if (!chunk.isDirectory()) FILE_LISTCSP.push(chunk.relative);
            cb(null, chunk)
        }));
});

gulp.task('create-xml-package:csp', function () {
    return new Promise((resolve, reject)=>{
        if (!FILE_LISTCSP || !Array.isArray(FILE_LISTCSP) || FILE_LISTCSP.length === 0)
            reject(new Error('Please, build project before create package.'));

        let append = '';

        for (let i = 0; i < FILE_LISTCSP.length; i++) {

            console.log('CSP: Adding file:', FILE_LISTCSP[i]);
            let content = fs.readFileSync('./build/' + FILE_LISTCSP[i], 'binary');
            content = new Buffer(content, 'binary').toString('base64');

            let step = 32767;
            let k = step;

            while (k < content.length) {
                content = content.substring(0,k) + '\r\n' + content.substring(k, content.length);
                k += step;
            }

            append +=

`<XData name="File${i}">
    <Description>${FILE_LISTCSP[i]}</Description>
    <MimeType>text/plain</MimeType>
    <Data><![CDATA[${content}]]></Data>
</XData>`;

        }

        append = '<Class name="SQLKPI.CSPData">' + append + '</Class>';
        fs.writeFileSync('./build/SQLKPI.CSPData.xml', append);

        FILE_LISTCSP.length = 0;
        resolve();
    });
});

let FILE_LISTCLS;
gulp.task('enum-files:cls', function() {
    FILE_LISTCLS = [];
    return gulp.src('SQLKPI/*.*',{read: false})
        .pipe(gulpIgnore.exclude('*.xml'))
        .pipe(through.obj(function (chunk, enc, cb) {
            if (!chunk.isDirectory()) FILE_LISTCLS.push(chunk.relative);
            cb(null, chunk)
        }));
});

gulp.task('create-xml-package:cls', function () {
    return new Promise((resolve, reject)=>{
        if (!FILE_LISTCLS || !Array.isArray(FILE_LISTCLS) || FILE_LISTCLS.length === 0)
            reject(new Error('Please, build project before create package.'));

        let append = '';

        for (let i = 0; i < FILE_LISTCLS.length; i++) {

            console.log('CLS: Adding file:', FILE_LISTCLS[i]);
            let content = fs.readFileSync('./SQLKPI/' + FILE_LISTCLS[i], 'binary');
            content = new Buffer(content, 'binary').toString('base64');

            let step = 32767;
            let k = step;

            while (k < content.length) {
                content = content.substring(0,k) + '\r\n' + content.substring(k, content.length);
                k += step;
            }

            append +=

                `<XData name="File${i}">
    <Description>${FILE_LISTCLS[i]}</Description>
    <MimeType>text/plain</MimeType>
    <Data><![CDATA[${content}]]></Data>
</XData>`;

        }

        append = '<Class name="SQLKPI.CLSData">' + append + '</Class>';
        fs.writeFileSync('./build/SQLKPI.CLSData.xml', append);

        FILE_LISTCLS.length = 0;
        resolve();
    });
});

gulp.task('concat-installer-files', function () {
    return new Promise((resolve,reject)=>{
        let installer = fs.readFileSync('./Installer.xml','utf8');
        let CLSFiles = fs.readFileSync('./build/SQLKPI.CLSData.xml','utf8');
        let CSPFiles = fs.readFileSync('./build/SQLKPI.CSPData.xml','utf8');

        installer = installer.substring(0,installer.length-11) + CLSFiles + CSPFiles + "</Export>";

        fs.writeFileSync('./build/Installer'+p.version+'.xml', installer);
        resolve();
    });
});

gulp.task('cleanup:before-creating-installer', function () {
    return new Promise((resolve,reject)=>{
        del('build/Installer*.xml');
        resolve();
    });
});

gulp.task('cleanup:after-creating-installer', function () {
    return new Promise((resolve,reject)=>{
        del('build/SQLKPI.*.xml');
        resolve();
    });
});

gulp.task('minify', gulp.series(gulp.parallel('minify:js','minify:css','minify:template'), 'concat-with-templates'));
gulp.task('copy', gulp.parallel('copy:csslibs','copy:jslibs','copy:fonts'));
gulp.task('build', gulp.series(gulp.parallel('lint','cleanup:before-build'),gulp.parallel('minify','copy'),'cleanup:after-build'));
gulp.task('create-xml-installer', gulp.series(
    'cleanup:before-creating-installer',
    gulp.parallel(gulp.series('enum-files:csp', 'create-xml-package:csp'), gulp.series('enum-files:cls', 'create-xml-package:cls')),
    'concat-installer-files',
    'cleanup:after-creating-installer'));

gulp.task('default',gulp.series('build', 'create-xml-installer'));
