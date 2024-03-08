package cn.iocoder.yudao.module.platform.service.logger;

import static cn.iocoder.yudao.framework.common.util.collection.CollectionUtils.convertSet;
import static cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformOperateLogDO.JAVA_METHOD_ARGS_MAX_LENGTH;
import static cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformOperateLogDO.RESULT_MAX_LENGTH;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.framework.common.util.string.StrUtils;
import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformOperateLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.operatelog.OperateLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.operatelog.OperateLogPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformOperateLogDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import cn.iocoder.yudao.module.platform.dal.mysql.logger.PlatformOperateLogMapper;
import cn.iocoder.yudao.module.platform.service.user.PlatformUserService;
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
