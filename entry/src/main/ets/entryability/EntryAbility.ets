import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { ImageKnife } from '@ohos/imageknife';
import { AsKey } from '../constants/AsKey';
import { Size } from '../constants/Size';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    ImageKnife.getInstance().initFileCache(this.context, 256, 256 * 1024 * 1024);
  }

  onDestroy(): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.getMainWindow((err, win) => {
      if (err?.code) {
        console.error('getMainWindow failed: ' + JSON.stringify(err));
        return;
      }
      win.setWindowLayoutFullScreen(true);
      windowStage.loadContent('pages/Index', (err) => {
        const context = win.getUIContext();
        const statusBarHeight = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;
        AppStorage.setOrCreate(AsKey.STATUS_BAR_HEIGHT, context.px2vp(statusBarHeight))
      });
    });
  }

  onWindowStageRestore(windowStage: window.WindowStage): void {
  }

  onWindowStageDestroy(): void {
  }

  onForeground(): void {
  }

  onBackground(): void {
  }
}