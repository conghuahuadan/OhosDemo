import { LengthMetrics } from "@kit.ArkUI"
import { ImageKnifeComponent } from "@ohos/imageknife";
import { ImageViewer } from "../ImageViewer";

@Component
export struct ImageViewerTestPage {
  @Consume pageInfos: NavPathStack;
  pics1: string[] = [
    "https://flash-scdn.jin10.com/flash_dli/jin_fanti/img/e3ba67a6-5f5d-ba78-3be8-1718784640728.jpg",
    "https://flash-scdn.jin10.com/8a22a6c8-f9f9-49c4-93bc-fa2d7c3a5747.png",
    "https://gd-hbimg.huaban.com/5af8c69096f047d7aa2c7366086e8a866c7f436d15248-fJQCru_fw1200",
    "https://flash-scdn.jin10.com/975427b4-37c2-415a-b029-1fe2d7f86bdc.png",
    "https://images.pexels.com/photos/2049422/pexels-photo-2049422.jpeg",
  // "https://upload.wikimedia.org/wikipedia/commons/8/87/Panorama_of_Hong_Kong_Harbour_from_The_Peak_dllu.jpg",
  ];
  pics2: string[] = [
    "https://flash-scdn.jin10.com/975427b4-37c2-415a-b029-1fe2d7f86bdc.png",
    "https://gd-hbimg.huaban.com/5af8c69096f047d7aa2c7366086e8a866c7f436d15248-fJQCru_fw1200",
    // "https://upload.wikimedia.org/wikipedia/commons/8/87/Panorama_of_Hong_Kong_Harbour_from_The_Peak_dllu.jpg",
    "https://flash-scdn.jin10.com/26ab97cb-61db-42c0-895c-f8e833945012.jpg",
  ];

  build() {
    NavDestination() {
      Column() {
        Stack() {

        }
        .height(44 + 24)

        Text("单图")
          .width('100%')
          .textAlign(TextAlign.Start)
          .height(50)
          .fontSize(16)
          .padding({ left: 16, right: 16 })
          .fontWeight(FontWeight.Bold)
          .fontColor("#cc000000")
          .backgroundColor("#f5f5f5")
          .borderRadius(2)
        Flex({
          space: {
            main: LengthMetrics.vp(12),
            cross: LengthMetrics.vp(12),
          },
          wrap: FlexWrap.Wrap,
        }) {
          ForEach(this.pics1, (url: string, index: number) => {
            if (index == 0) {
              ImageKnifeComponent({
                imageKnifeOption: {
                  loadSrc: url,
                  objectFit: ImageFit.TOP,
                }
              })
                .key(url)
                .height(120)
                .aspectRatio(4 / 3)
                .borderRadius(2)
                .backgroundColor("#f5f5f5")
                .onClick(() => {
                  new ImageViewer(this.pageInfos).setPath(url).show();
                })
            } else {
              Image(url)
                .objectFit(ImageFit.TOP)
                .height(120)
                .aspectRatio(4 / 3)
                .borderRadius(2)
                .backgroundColor("#f5f5f5")
                .onClick(() => {
                  new ImageViewer(this.pageInfos).setPath(url).show();
                })
            }
          })
        }
        .margin({
          top: 12,
        })

        Text("多图")
          .width('100%')
          .textAlign(TextAlign.Start)
          .height(50)
          .fontSize(16)
          .padding({ left: 16, right: 16 })
          .fontWeight(FontWeight.Bold)
          .fontColor("#cc000000")
          .backgroundColor("#f5f5f5")
          .margin({
            top: 24,
          })
          .borderRadius(2)
        Flex({
          space: {
            main: LengthMetrics.vp(12),
            cross: LengthMetrics.vp(12),
          },
          wrap: FlexWrap.Wrap,
        }) {
          ForEach(this.pics2, (url: string, index: number) => {
            Image(url)
              .objectFit(ImageFit.TOP)
              .height(120)
              .aspectRatio(4 / 3)
              .borderRadius(2)
              .backgroundColor("#f5f5f5")
              .onClick(() => {
                new ImageViewer(this.pageInfos).setPaths(this.pics2).setIndex(index).show();
              })
          })
        }
        .margin({
          top: 12,
        })
      }.padding({
        left: 16,
        right: 16,
      })
    }
    .hideTitleBar(true)
  }
}