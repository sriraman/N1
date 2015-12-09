import N1Launcher from './n1-launcher'

describe('Logged in app boot', () => {
  beforeAll((done)=>{
    // Boot in dev mode with no arguments
    this.app = new N1Launcher(["--dev"]);
    this.app.mainWindowReady().finally(done);
  });
});
