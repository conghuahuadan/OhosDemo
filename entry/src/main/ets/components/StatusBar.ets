import { ProjectUtil } from "../utils/ProjectUtil";

@Component
export struct StatusBar {
  build() {
    Blank().height(ProjectUtil.getStatusBarHeight())
  }
}