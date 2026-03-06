import { AsKey } from "../constants/AsKey";

export class ProjectUtil {
  static getStatusBarHeight(): number {
    return AppStorage.get<number>(AsKey.STATUS_BAR_HEIGHT) ?? 0;
  }
}