fs = require 'fs'
path = require 'path'
request = require 'request'
proc = require 'child_process'

executeTests = (test, grunt, done)->
  testSucceeded = false
  testOutput = ""
  testProc = proc.spawn(test.cmd, test.args)
  testProc.stdout.on 'data', (data) ->
    str = data.toString()
    testOutput += str
    console.log(str)
    if str.indexOf(' 0 failures') isnt -1
      testSucceeded = true

  testProc.stderr.on 'data', (data) ->
    str = data.toString()
    testOutput += str
    grunt.log.error(str)

  testProc.on 'error', (err) ->
    grunt.log.error("Process error: #{err}")

  testProc.on 'close', (exitCode, signal) ->
    if testSucceeded
      done()
    else
      testOutput = testOutput.replace(/\x1b\[[^m]+m/g, '')
      url = "https://hooks.slack.com/services/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"
      request.post
        url: url
        json:
          username: "Edgehill Builds"
          text: "Aghhh somebody broke the build. ```#{testOutput}```"
      , (err, httpResponse, body) ->
        done(false)

module.exports = (grunt) ->

  grunt.registerTask 'run-spectron-specs', 'Run spectron specs', ->
    done = @async()
    process.chdir('./spectron')
    npmPath = path.resolve "../build/node_modules/.bin/npm"
    installProc = proc.execSync('npm install')
    executeTests cmd: 'npm', args: ['test'], grunt, done
    process.chdir('..')


  grunt.registerTask 'run-edgehill-specs', 'Run the specs', ->
    done = @async()
    executeTests cmd: './N1.sh', args: ['--test'], grunt, done
