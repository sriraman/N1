import path from 'path'
import {Application} from 'spectron';
import {FAKE_DATA_PATH} from './config-helper';

export default class N1Launcher extends Application {
  constructor(launchArgs = []) {
    super({
      path: N1Launcher.electronPath(),
      args: [jasmine.NYLAS_ROOT_PATH].concat(N1Launcher.defaultNylasArgs()).concat(launchArgs)
    })
  }

  mainWindowReady() {
    return this.windowReady(N1Launcher.mainWindowMatcher).then(() => {
      return new Promise((resolve, reject)=>{
        this.client.execute((FAKE_DATA_PATH)=>{
          require('nylas-exports').AccountStore._importFakeData(FAKE_DATA_PATH)
        }, FAKE_DATA_PATH)

        // We need to wait for the client exeuction to finish.
        //
        // `this.client.execute` returns immediately and doesn't wait for
        // the Promise to finish
        setTimeout(resolve, 100)
      })
    });
  }

  popoutComposerWindowReady() {
    return this.windowReady(N1Launcher.mainWindowMatcher).then(() => {
      return this.client.execute(()=>{
        require('nylas-exports').Actions.composeNewBlankDraft();
      })
    }).then(()=>{
      return N1Launcher.waitUntilMatchingWindowLoaded(this.client, N1Launcher.composerWindowMatcher).then((windowId)=>{
        return this.client.window(windowId)
      })
    })
  }

  windowReady(matcher) {
    return this.start().then(()=>{
      return N1Launcher.waitUntilMatchingWindowLoaded(this.client, matcher).then((windowId)=>{
        return this.client.window(windowId)
      })
    });
  }

  static mainWindowMatcher(client) {
    return client.isExisting(".main-window-loaded").then((exists)=>{
      if (exists) {return true} else {return false}
    })
  }

  static composerWindowMatcher(client) {
    return client.execute(()=>{
      return NylasEnv.getLoadSettings().windowType;
    }).then(({value})=>{
      if(value === "composer") {
        return client.isExisting(".contenteditable")
      } else {
        return false
      }
    })
  }

  static defaultNylasArgs() {
    return ["--enable-logging", `--resource-path=${jasmine.NYLAS_ROOT_PATH}`]
  }

  static electronPath() {
    nylasRoot = jasmine.NYLAS_ROOT_PATH
    if (process.platform === "darwin") {
      return path.join(nylasRoot, "electron", "Electron.app", "Contents", "MacOS", "Electron")
    } else if (process.platform === "win32") {
      return path.join(nylasRoot, "electron", "electron.exe")
    }
    else if (process.platform === "linux") {
      return path.join(nylasRoot, "electron", "electron")
    }
    else {
      throw new Error(`Platform ${process.platform} is not supported`)
    }
  }

  // We unfortunatley can't just Spectron's `waitUntilWindowLoaded` because
  // the first window that loads isn't necessarily the main render window (it
  // could be the work window or others), and once the window is "loaded"
  // it'll take a while for packages to load, etc. As such we periodically
  // poll the list of windows to find one that looks like the main loaded
  // window.
  //
  // Returns a promise that resolves with the main window's ID once it's
  // loaded.
  static waitUntilMatchingWindowLoaded(client, matcher, lastCheck=0) {
    var CHECK_EVERY = 500
    return new Promise((resolve, reject) => {
      return client.windowHandles().then(({value}) => {
        return Promise.mapSeries(value, (windowId)=>{
          return N1Launcher.switchAndCheckForMatch(client, windowId, matcher)
        })
      }).then((windowIdChecks)=>{
        for (windowId of windowIdChecks) {
          if (windowId) {return resolve(windowId)}
        }

        var now = Date.now();
        var delay = Math.max(CHECK_EVERY - (now - lastCheck), 0)
        setTimeout(()=>{
          return N1Launcher.waitUntilMatchingWindowLoaded(client, matcher, now).then(resolve)
        }, delay)
      }).catch((err) => {
        console.error(err);
      });
    });
  }

  // Returns false or the window ID of the main window
  // The `matcher` resolves to a boolean.
  static switchAndCheckForMatch(client, windowId, matcher) {
    return client.window(windowId).then(()=>{
      return matcher(client).then((isMatch) => {
        if (isMatch) {return windowId} else {return false}
      });
    })
  }
}
