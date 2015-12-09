import N1Launcher from './n1-launcher'
import {currentConfig} from './config-helper'

fdescribe('Logged in app boot', () => {
  beforeAll((done)=>{
    // Boot in dev mode with no arguments
    this.app = new N1Launcher(["--dev"]);
    this.app.mainWindowReady().finally(done);
  });

  afterAll((done)=> {
    if (this.app && this.app.isRunning()) {
      this.app.stop().finally(done);
    } else {
      done()
    }
  });

  it("has the autoupdater pointing to the correct url", () => {
    this.app.client.execute(()=>{
      app = require('remote').getGlobal('application')
      return {
        platform: process.platform,
        arch: process.arch,
        feedUrl: app.autoUpdateManager.feedURL
      }
    }).then(({value})=>{
      base = "https://edgehill.nylas.com/update-check"
      config = currentConfig()
      email = encodeURIComponent(config.email)
      url = `${base}?platform=${value.platform}&arch=${value.arch}&version=${config.version}&id=${config.id}&emails=${email}`
      expect(value.feedUrl).toEqual(url)
    })
  });


  it("has main window visible", (done)=> {
    this.app.client.isWindowVisible()
    .then((result)=>{ expect(result).toBe(true) })
    .finally(done)
  });

  it("has main window focused", (done)=> {
    this.app.client.isWindowFocused()
    .then((result)=>{ expect(result).toBe(true) })
    .finally(done)
  });

  it("isn't minimized", (done)=> {
    this.app.client.isWindowMinimized()
    .then((result)=>{ expect(result).toBe(false) })
    .finally(done)
  });

  it("doesn't have the dev tools open", (done)=> {
    this.app.client.isWindowDevToolsOpened()
    .then((result)=>{ expect(result).toBe(false) })
    .finally(done)
  });

  it("restored its width from file", (done)=> {
    this.app.client.getWindowWidth()
    .then((result)=>{ expect(result).toBe(1234) })
    .finally(done)
  });

  it("restored its height from file", (done)=> {
    this.app.client.getWindowHeight()
    .then((result)=>{ expect(result).toBe(789) })
    .finally(done)
  });
});
