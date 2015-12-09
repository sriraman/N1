import N1Launcher from './n1-launcher'

describe('Clean app boot', function() {
  beforeAll((done)=>{
    // Boot in dev mode with no arguments
    this.app = new N1Launcher(["--dev"], N1Launcher.CLEAR_CONFIG);
    this.app.onboardingWindowReady().finally(done);
  });

  afterAll((done)=> {
    if (this.app && this.app.isRunning()) {
      this.app.stop().finally(done);
    } else {
      done()
    }
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

  it("has width", (done)=> {
    this.app.client.getWindowWidth()
    .then((result)=>{ expect(result).toBeGreaterThan(0) })
    .finally(done)
  });

  it("has height", (done)=> {
    this.app.client.getWindowHeight()
    .then((result)=>{ expect(result).toBeGreaterThan(0) })
    .finally(done)
  });
});
