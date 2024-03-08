package cn.iocoder.yudao.framework.common.enums.utils;

import java.util.*;

/**
 * 定义枚举工具类
 *
 * @author 朱述勇
 * @since 2022/12/10 12:31
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
public class EnumUtil {

    /**
     * 通过传入的code获取code的描述信息
     * @param code 传入的code值
     * @param tClass 指定的枚举类
     * @param <T> 枚举类泛型
     * @return name值
     */
    public static <T extends CodeEnum> String getByCode(Integer code, Class<T> tClass){
        for (T enumClass: tClass.getEnumConstants()){
            if (enumClass.getCode().equals(code)){
                return enumClass.getName();
            }
        }
        return "";
    }

    /**
     * 通过传入的code和传入的枚举类获取code对应的枚举类对象
     * @param code code值
     * @param tClass 枚举类
     * @param <T> 目标枚举类
     * @return 目标枚举类
     */
    public static <T extends CodeEnum> T getEnumObjectByCode(Integer code, Class<T> tClass) {
        for (T enumClass : tClass.getEnumConstants()) {
            if (enumClass.getCode().equals(code)) {
                return enumClass;
            }
        }
        return null;
    }

    /**
     * 通过传入指定的枚举泛型类获取对应枚举类map结构的key,value
     * @param tClass 传入指定的枚举泛型类
     * @param excludeCode 传入需要排除的code的键值对
     * @param <T> 枚举类泛型
     * @return 对应枚举类map结构的key,value
     */
    public static <T extends CodeEnum> Map<Integer, String> getEnumToMap(Class<T> tClass, List<Integer> excludeCode){
        Map<Integer, String> map = new HashMap<Integer, String>();
        for (T enumClass : tClass.getEnumConstants()){
            map.put(enumClass.getCode(),enumClass.getName());
        }
        if (excludeCode!=null&&excludeCode.size()>0){
            for (Integer code: excludeCode){
                map.remove(code);
            }
        }
        return map;
    }

    /**
     * 通过传入指定的枚举泛型类获取对应枚举类code的List数组
     * @param tClass 传入指定的枚举泛型类
     * @param excludeCode 传入需要排除的code的键值对
     * @param <T> 枚举类泛型
     * @return 对应枚举类map结构的key,value
     */
    public static <T extends CodeEnum> List<Integer> getEnumToList(Class<T> tClass, List<Integer> excludeCode){
        List<Integer> rtnList = new ArrayList<Integer>();
        for (T enumClass: tClass.getEnumConstants()){
            rtnList.add(enumClass.getCode());
        }
        if (excludeCode!=null&&excludeCode.size()>0){
            for (Integer code: excludeCode){
                rtnList.remove(code);
            }
        }
        return rtnList;
    }

    /**
     * 通过传入指定的枚举泛型类获取对应枚举类map结构的key,value
     * @param tClass 传入指定的枚举泛型类
     * @param excludeCode 传入需要排除的code的键值对
     * @param <T> 枚举类泛型
     * @return 对应枚举类map结构的key,value
     */
    public static <T extends CodeEnum> LinkedHashMap<Integer, String> getEnumToLinkedHashMap(Class<T> tClass, List<Integer> excludeCode){
        LinkedHashMap<Integer, String> map = new LinkedHashMap<>();
        for (T enumClass: tClass.getEnumConstants()){
            map.put(enumClass.getCode(),enumClass.getName());
        }
        if (excludeCode!=null&&excludeCode.size()>0){
            for (Integer code: excludeCode){
                map.remove(code);
            }
        }
        return map;
    }
}
