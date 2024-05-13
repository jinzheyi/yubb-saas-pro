package com.shengyu.module.platform.api.plug;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.api.plug.dto.PlugAppPageReqDTO;
import com.shengyu.module.platform.api.plug.dto.PlugAppRespDTO;
import com.shengyu.module.platform.api.plug.dto.PlugAppSimpleRespDTO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppPageReqVO;
import com.shengyu.module.platform.dal.dataobject.plug.PlugAppDO;
import com.shengyu.module.platform.service.plug.PlugAppService;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * @Description 插件app接口实现
 * @Author zhusy
 * @Date 2023/4/13 10:57
 * @Version 1.0
 **/
@Service
public class PlugAppApiImpl implements PlugAppApi {

    @Resource
    private PlugAppService plugAppService;

    @Override
    public PlugAppRespDTO getPlugApp(Long id) {
        return BeanUtils.toBean(plugAppService.getPlugApp(id), PlugAppRespDTO.class);
    }

    @Override
    public List<PlugAppSimpleRespDTO> getPlugAppList(List<Long> ids, List<String> appSns) {
        return BeanUtils.toBean(plugAppService.getPlugAppList(ids, appSns), PlugAppSimpleRespDTO.class);
    }

    @Override
    public PageResult<PlugAppSimpleRespDTO> getPlugAppPage(PlugAppPageReqDTO reqDTO) {
        PlugAppPageReqVO plugAppPageReqVO = BeanUtils.toBean(reqDTO, PlugAppPageReqVO.class);
        //只查询上架的
        plugAppPageReqVO.setStatus(CommonStatusEnum.ENABLE.getStatus());
        //只查询启用的
        plugAppPageReqVO.setEnable(CommonStatusEnum.ENABLE.getStatus());
        PageResult<PlugAppDO> plugAppPage = plugAppService.getPlugAppPage(plugAppPageReqVO);
        return BeanUtils.toBean(plugAppPage, PlugAppSimpleRespDTO.class);
    }

}
