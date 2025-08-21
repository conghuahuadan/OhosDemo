import { JSON } from "@kit.ArkTS";
import { image } from "@kit.ImageKit";
import axios, { AxiosResponse } from "@ohos/axios";
import { BusinessError } from "@kit.BasicServicesKit";
import { HDImageViewer } from "hdimageviewer/src/main/ets/components/MainPage/HDImageViewer";
import { ImageSubView } from "./ImageSubView";
import { window } from "@kit.ArkUI";
import { common } from "@kit.AbilityKit";
import { WindowUtil } from "@pura/harmony-utils";

@Component
export struct ImageViewerPage {
  params?: Record<string, Object>;
  @State alpha: number = 1;
  paths: string[] = [];
  index: number = 0;
  controller: SwiperController = new SwiperController();
  @Consume pageInfos: NavPathStack;
  context = getContext(this) as common.UIAbilityContext

  aboutToAppear(): void {
    this.paths = this.params?.["paths"] as string[];
    this.index = this.params?.["index"] as number;

    WindowUtil.setSpecificSystemBarEnabled('status', false)
  }

  aboutToDisappear(): void {
    WindowUtil.setSpecificSystemBarEnabled('status', true)
  }

  build() {
    NavDestination() {
      Column() {
        Swiper(this.controller) {
          ForEach(this.paths, (value: string) => {
            ImageSubView({
              path: value,
              paths: this.paths,
              alpha: this.alpha,
              onDismiss: () => {
                this.pageInfos.pop();
              }
            })
          })
        }
        .index(this.index)
        .indicator(this.paths.length > 1)
        .loop(false)
      }
    }
    .backgroundColor("#ffffff")
    .opacity(this.alpha)
    .hideTitleBar(true)
    .customTransition((op: NavigationOperation, isEnter: boolean): Array<NavDestinationTransition> | undefined => {
      let transitionOneEvent = () => {
      };
      if (op === NavigationOperation.PUSH) {
        if (isEnter) {
          this.alpha = 0;
          transitionOneEvent = () => {
            this.alpha = 1;
          };
        }
      } else if (op === NavigationOperation.POP) {
        if (!isEnter) {
          transitionOneEvent = () => {
            this.alpha = 0;
          };
        }
      }
      const transitionOne: NavDestinationTransition = {
        duration: 100,
        delay: 0,
        curve: Curve.EaseInOut,
        event: transitionOneEvent,
        onTransitionEnd: () => {
        }
      };
      return [transitionOne];
    })
    .mode(NavDestinationMode.DIALOG)
  }
}
