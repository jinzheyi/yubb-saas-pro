package com.shengyu.framework.common.enums;

import com.shengyu.framework.common.enums.utils.CodeEnum;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(<a href="https://gitee.com/jinzheyi">jinzheyi</a>)作者：朱述勇<br/>
 * GitHub(<a href="https://github.com/jinzheyi">jinzheyi</a>)作者：朱述勇 。
 * @since 2023/4/9 13:10
 */
@NoArgsConstructor
public class CommonConstants {

    /**
     * 平台超管用户名
     */
    public static final String USER_NAME = "admin";

    /**
     * 租户管理员标识
     */
    public static final String TENANT_ADMIN = "tenant_admin";

    public static final String SY = "sy";

    /**
     * 应用订单状态
     */
    @Getter
    @AllArgsConstructor
    public enum PlugOrderStatusEnum implements CodeEnum {
        /**
         * 待审核
         */
        ZERO(0, "待审核"),
        ONE(1, "通过"),
        TWO(2, "不通过"),
        THREE(3, "拒绝审核"),
        ;

        private final Integer code;
        private final String name;
    }

    /**
     * 工作流模块
     */
    public static final String BPM_CODE = "shengyu_flow";
    /**
     * 商城系统
     */
    public static final String MALL_CODE = "shengyu_mall";
    /**
     * 支付系统
     */
    public static final String PAY_CODE = "shengyu_pay";
    /**
     * 会员中心
     */
    public static final String MEMBER_CODE = "shengyu_member";


    /**
     * 定义的应用功能编码（要跟添加的应用编码保持一致）
     */
    @Getter
    @AllArgsConstructor
    public enum PlugAppSnEnum {
        BPM(BPM_CODE, "工作流模块"),
        MALL(MALL_CODE, "商城系统"),
        PAY(PAY_CODE, "支付系统"),
        MEMBER(MEMBER_CODE, "会员中心"),
        ;

        /**
         * 应用功能appSn
         */
        private final String code;
        /**
         * 应用名称
         */
        private final String name;

        /**
         * 通过传入的code获取code的描述信息
         * @param code 传入的code
         * @return 描述信息
         */
        public static String getValueByCode(String code){
            for (PlugAppSnEnum appSnEnum: PlugAppSnEnum.values()){
                if (appSnEnum.getCode().equals(code)){
                    return appSnEnum.getName();
                }
            }
            return "";
        }

    }

    /**
     * 菜单维度
     */
    @Getter
    @AllArgsConstructor
    public enum MenuDimensionEnum implements CodeEnum {
        /**
         * 普通菜单
         */
        MENU(0, "普通菜单"),
        PLUG(1, "插件菜单"),
        ;

        private final Integer code;
        private final String name;
    }


}
