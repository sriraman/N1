import Application from '../../../spectron/lib/application.js';

describe('Nylas', ()=> {
  beforeAll((done)=>{
    console.log("---> Booting up Nylas");
    args = jasmine.APP_ARGS.join(' ');
    console.log(`     $ ${jasmine.APP_PATH} ${args}`);
    console.log(jasmine.APP_ARGS);

    appPath = "/Applications/Nylas N1.app/Contents/MacOS/Nylas"
    electronPath = "/Users/evanmorikawa/Code/edgehill/N1/electron/Electron.app/Contents/MacOS/Electron"
    N1Path = "/Users/evanmorikawa/Code/edgehill/N1"

    this.app = new Application({
      path: electronPath,
      args: [N1Path, "--test=window", `--resource-path=${N1Path}`]
    });

    this.app.start().then(()=> {
      console.log("=============== STARTING =================")
      this.app.client.windowHandles().then((handles)=> {
        console.log("Window handles:");
        console.log(JSON.stringify(handles));
      });
      setTimeout(done, jasmine.BOOT_WAIT)
    });
  });

  afterEach((done)=> {
    if (this.app && this.app.isRunning()) {
      this.app.stop().then(done);
    }
  });

  it('boots 4 windows on launch', (done)=> {
    this.app.client.getWindowCount().then((count)=> {
      expect(count).toEqual(4);
      done();
    });
  });
});

