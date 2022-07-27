package cn.iocoder.yudao.module.platform.service.oauth2;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.string.StrUtils;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.auth.OAuth2ClientConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import cn.iocoder.yudao.module.platform.dal.mapper.oauth2.PlatformOAuth2ClientMapper;
import cn.iocoder.yudao.module.platform.mq.producer.auth.PlatformOAuth2ClientProducer;
import com.google.common.annotations.VisibleForTesting;
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import java.util.Collection;
import java.util.Date;
import java.util.List;
import java.util.Map;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.framework.common.util.collection.CollectionUtils.convertMap;
import static cn.iocoder.yudao.framework.common.util.collection.CollectionUtils.getMaxValue;
import static cn.iocoder.yudao.module.platform.enums.PlatformErrorCodeConstants.*;

/**
 * OAuth2.0 Client Service 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
@Slf4j
public class PlatformOAuth2ClientServiceImpl implements PlatformOAuth2ClientService {

    /**
     * 定时执行 {@link #schedulePeriodicRefresh()} 的周期
     * 因为已经通过 Redis Pub/Sub 机制，所以频率不需要高
     */
    private static final long SCHEDULER_PERIOD = 5 * 60 * 1000L;

    /**
     * 客户端缓存
     * key：客户端编号 {@link PlatformOAuth2ClientDO#getClientId()} ()}
     *
     * 这里声明 volatile 修饰的原因是，每次刷新时，直接修改指向
     */
    @Getter // 解决单测
    @Setter // 解决单测
    private volatile Map<String, PlatformOAuth2ClientDO> clientCache;
    /**
     * 缓存角色的最大更新时间，用于后续的增量轮询，判断是否有更新
     */
    @Getter
    private volatile Date maxUpdateTime;

    @Resource
    private PlatformOAuth2ClientMapper platformOAuth2ClientMapper;

    @Resource
    private PlatformOAuth2ClientProducer platformOAuth2ClientProducer;

    /**
     * 初始化 {@link #clientCache} 缓存
     */
    @Override
    @PostConstruct
    public void initLocalCache() {
        // 获取客户端列表，如果有更新
        List<PlatformOAuth2ClientDO> platformOAuth2ClientDOList = loadOAuth2ClientIfUpdate(maxUpdateTime);
        if (CollUtil.isEmpty(platformOAuth2ClientDOList)) {
            return;
        }

        // 写入缓存
        clientCache = convertMap(platformOAuth2ClientDOList, PlatformOAuth2ClientDO::getClientId);
        //取出最大的更新时间
        maxUpdateTime = getMaxValue(platformOAuth2ClientDOList, PlatformOAuth2ClientDO::getUpdateTime);
        log.info("[initLocalCache][初始化 OAuth2Client 数量为 {}]", platformOAuth2ClientDOList.size());
    }

    @Scheduled(fixedDelay = SCHEDULER_PERIOD, initialDelay = SCHEDULER_PERIOD)
    public void schedulePeriodicRefresh() {
        initLocalCache();
    }

    /**
     * 如果客户端发生变化，从数据库中获取最新的全量客户端。
     * 如果未发生变化，则返回空
     *
     * @param maxUpdateTime 当前客户端的最大更新时间
     * @return 客户端列表
     */
    private List<PlatformOAuth2ClientDO> loadOAuth2ClientIfUpdate(Date maxUpdateTime) {
        // 第一步，判断是否要更新。
        if (maxUpdateTime == null) { // 如果更新时间为空，说明 DB 一定有新数据
            log.info("[loadOAuth2ClientIfUpdate][首次加载全量客户端]");
        } else { // 判断数据库中是否有更新的客户端
            if (platformOAuth2ClientMapper.selectCountByUpdateTimeGt(maxUpdateTime) == 0) {
                return null;
            }
            log.info("[loadOAuth2ClientIfUpdate][增量加载全量客户端]");
        }
        // 第二步，如果有更新，则从数据库加载所有客户端
        return platformOAuth2ClientMapper.selectList();
    }

    @Override
    public Long createOAuth2Client(OAuth2ClientCreateReqVO createReqVO) {
        validateClientIdExists(null, createReqVO.getClientId());
        // 插入
        PlatformOAuth2ClientDO oauth2Client = OAuth2ClientConvert.INSTANCE.convert(createReqVO);
        platformOAuth2ClientMapper.insert(oauth2Client);
        // 发送刷新消息
        platformOAuth2ClientProducer.sendOAuth2ClientRefreshMessage();
        return oauth2Client.getId();
    }

    @Override
    public void updateOAuth2Client(OAuth2ClientUpdateReqVO updateReqVO) {
        // 校验存在
        validateOAuth2ClientExists(updateReqVO.getId());
        // 校验 Client 未被占用
        validateClientIdExists(updateReqVO.getId(), updateReqVO.getClientId());

        // 更新
        PlatformOAuth2ClientDO updateObj = OAuth2ClientConvert.INSTANCE.convert(updateReqVO);
        platformOAuth2ClientMapper.updateById(updateObj);
        // 发送刷新消息
        platformOAuth2ClientProducer.sendOAuth2ClientRefreshMessage();
    }

    @Override
    public void deleteOAuth2Client(Long id) {
        // 校验存在
        validateOAuth2ClientExists(id);
        // 删除
        platformOAuth2ClientMapper.deleteById(id);
        // 发送刷新消息
        platformOAuth2ClientProducer.sendOAuth2ClientRefreshMessage();
    }

    private void validateOAuth2ClientExists(Long id) {
        if (platformOAuth2ClientMapper.selectById(id) == null) {
            throw exception(OAUTH2_CLIENT_NOT_EXISTS);
        }
    }

    @VisibleForTesting
    void validateClientIdExists(Long id, String clientId) {
        PlatformOAuth2ClientDO client = platformOAuth2ClientMapper.selectByClientId(clientId);
        if (client == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的客户端
        if (id == null) {
            throw exception(OAUTH2_CLIENT_EXISTS);
        }
        if (!client.getId().equals(id)) {
            throw exception(OAUTH2_CLIENT_EXISTS);
        }
    }

    @Override
    public PlatformOAuth2ClientDO getOAuth2Client(Long id) {
        return platformOAuth2ClientMapper.selectById(id);
    }

    @Override
    public PageResult<PlatformOAuth2ClientDO> getOAuth2ClientPage(OAuth2ClientPageReqVO pageReqVO) {
        return platformOAuth2ClientMapper.selectPage(pageReqVO);
    }

    @Override
    public PlatformOAuth2ClientDO validOAuthClientFromCache(String clientId, String clientSecret,
                                                            String authorizedGrantType, Collection<String> scopes, String redirectUri) {
        // 校验客户端存在、且开启
        PlatformOAuth2ClientDO client = clientCache.get(clientId);
        if (client == null) {
            throw exception(OAUTH2_CLIENT_NOT_EXISTS);
        }
        if (ObjectUtil.notEqual(client.getStatus(), CommonStatusEnum.ENABLE.getStatus())) {
            throw exception(OAUTH2_CLIENT_DISABLE);
        }

        // 校验客户端密钥
        if (StrUtil.isNotEmpty(clientSecret) && ObjectUtil.notEqual(client.getSecret(), clientSecret)) {
            throw exception(OAUTH2_CLIENT_CLIENT_SECRET_ERROR);
        }
        // 校验授权方式
        if (StrUtil.isNotEmpty(authorizedGrantType) && !CollUtil.contains(client.getAuthorizedGrantTypes(), authorizedGrantType)) {
            throw exception(OAUTH2_CLIENT_AUTHORIZED_GRANT_TYPE_NOT_EXISTS);
        }
        // 校验授权范围
        if (CollUtil.isNotEmpty(scopes) && !CollUtil.containsAll(client.getScopes(), scopes)) {
            throw exception(OAUTH2_CLIENT_SCOPE_OVER);
        }
        // 校验回调地址
        if (StrUtil.isNotEmpty(redirectUri) && !StrUtils.startWithAny(redirectUri, client.getRedirectUris())) {
            throw exception(OAUTH2_CLIENT_REDIRECT_URI_NOT_MATCH, redirectUri);
        }
        return client;
    }

}
