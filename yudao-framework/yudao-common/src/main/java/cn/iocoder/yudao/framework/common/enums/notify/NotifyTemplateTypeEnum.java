package cn.iocoder.yudao.framework.common.enums.notify;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * @author 朱述勇
 * @data: 2024-02-07  10:49
 * @Description:
 * @Version: 江西财信科技版权所有 1.0
 */
@Getter
@AllArgsConstructor
public enum NotifyTemplateTypeEnum {

  /**
   * 系统消息
   */
  SYSTEM_MESSAGE(2),
  /**
   * 通知消息
   */
  NOTIFICATION_MESSAGE(1);

  private final Integer type;

}
