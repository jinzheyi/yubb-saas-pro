package cn.iocoder.yudao.module.platform.api.dict;

import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataRespDTO;
import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataSimpleRespDTO;

import java.util.Collection;
import java.util.List;

/**
 * 字典数据 API 接口
 *
 * @author 圣钰科技
 */
public interface DictDataApi {

    /**
     * 校验字典数据们是否有效。如下情况，视为无效：
     * 1. 字典数据不存在
     * 2. 字典数据被禁用
     *
     * @param dictType 字典类型
     * @param values 字典数据值的数组
     */
    void validateDictDataList(String dictType, Collection<String> values);

    /**
     * 获得指定的字典数据，从缓存中
     *
     * @param type 字典类型
     * @param value 字典数据值
     * @return 字典数据
     */
    DictDataRespDTO getDictData(String type, String value);

    /**
     * 解析获得指定的字典数据，从缓存中
     *
     * @param type 字典类型
     * @param label 字典数据标签
     * @return 字典数据
     */
    DictDataRespDTO parseDictData(String type, String label);

    /**
     * 获得字典数据列表
     *
     * @return 字典数据全列表
     */
    List<DictDataSimpleRespDTO> getDictDataList();

    /**
     * 获得字典数据列表
     *
     * @param dictType 字典类型
     * @return 字典数据列表
     */
    List<DictDataRespDTO> getEnabledDictDataListByType(String dictType);

}
