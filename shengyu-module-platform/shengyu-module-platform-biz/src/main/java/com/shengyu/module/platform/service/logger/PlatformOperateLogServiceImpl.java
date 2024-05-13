package com.shengyu.module.platform.service.logger;

import static com.shengyu.framework.common.util.collection.CollectionUtils.convertSet;
import static com.shengyu.module.platform.dal.dataobject.logger.PlatformOperateLogDO.JAVA_METHOD_ARGS_MAX_LENGTH;
import static com.shengyu.module.platform.dal.dataobject.logger.PlatformOperateLogDO.RESULT_MAX_LENGTH;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.common.util.string.StrUtils;
import com.shengyu.module.platform.api.logger.dto.PlatformOperateLogCreateReqDTO;
import com.shengyu.module.platform.controller.platform.logger.vo.operatelog.OperateLogExportReqVO;
import com.shengyu.module.platform.controller.platform.logger.vo.operatelog.OperateLogPageReqVO;
import com.shengyu.module.platform.dal.dataobject.logger.PlatformOperateLogDO;
import com.shengyu.module.platform.dal.dataobject.user.PlatformUserDO;
import com.shengyu.module.platform.dal.mysql.logger.PlatformOperateLogMapper;
import com.shengyu.module.platform.service.user.PlatformUserService;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

@Service
@Validated
@Slf4j
public class PlatformOperateLogServiceImpl implements PlatformOperateLogService {

    @Resource
    private PlatformOperateLogMapper platformOperateLogMapper;

    @Resource
    private PlatformUserService platformUserService;

    @Override
    public void createOperateLog(PlatformOperateLogCreateReqDTO createReqDTO) {
        PlatformOperateLogDO logDO = BeanUtils.toBean(createReqDTO, PlatformOperateLogDO.class);
        logDO.setJavaMethodArgs(StrUtils.maxLength(logDO.getJavaMethodArgs(), JAVA_METHOD_ARGS_MAX_LENGTH));
        logDO.setResultData(StrUtils.maxLength(logDO.getResultData(), RESULT_MAX_LENGTH));
        platformOperateLogMapper.insert(logDO);
    }

    @Override
    public PageResult<PlatformOperateLogDO> getOperateLogPage(OperateLogPageReqVO reqVO) {
        // 处理基于用户昵称的查询
        Collection<Long> userIds = null;
        if (StrUtil.isNotEmpty(reqVO.getUserNickname())) {
            userIds = convertSet(platformUserService.getUserListByNickname(reqVO.getUserNickname()), PlatformUserDO::getId);
            if (CollUtil.isEmpty(userIds)) {
                return PageResult.empty();
            }
        }
        // 查询分页
        return platformOperateLogMapper.selectPage(reqVO, userIds);
    }

    @Override
    public List<PlatformOperateLogDO> getOperateLogList(OperateLogExportReqVO reqVO) {
        // 处理基于用户昵称的查询
        Collection<Long> userIds = null;
        if (StrUtil.isNotEmpty(reqVO.getUserNickname())) {
            userIds = convertSet(platformUserService.getUserListByNickname(reqVO.getUserNickname()), PlatformUserDO::getId);
            if (CollUtil.isEmpty(userIds)) {
                return Collections.emptyList();
            }
        }
        // 查询列表
        return platformOperateLogMapper.selectList(reqVO, userIds);
    }

}
