package com.shengyu.module.system.service.user;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertList;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertSet;
import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_ADMIN;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_COUNT_MAX;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_CREATE_SAAS_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_IS_DISABLE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_NOT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_PASSWORD_FAILED;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_SAAS_ID_UNIQUE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_SAAS_MOBILE_NOT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_SAAS_USERNAME_NOT_EXISTS;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.collection.CollectionUtil;
import cn.hutool.core.date.DateUtil;
import cn.hutool.core.io.IoUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.collection.CollectionUtils;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.common.util.string.StrUtils;
import com.shengyu.framework.datapermission.core.util.DataPermissionUtils;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.module.infra.api.file.FileApi;
import com.shengyu.module.platform.api.mail.MailSendApi;
import com.shengyu.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import com.shengyu.module.system.api.user.dto.AdminUserCreateReqDTO;
import com.shengyu.module.system.controller.admin.user.vo.profile.UserProfileUpdatePasswordReqVO;
import com.shengyu.module.system.controller.admin.user.vo.profile.UserProfileUpdateReqVO;
import com.shengyu.module.system.controller.admin.user.vo.user.MyTenantRespVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserPageReqVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserSaveReqVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserUpdateReqVO;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.dataobject.dept.UserPostDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.dataobject.user.SaasUserDO;
import com.shengyu.module.system.dal.mysql.dept.UserPostMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.dal.mysql.user.SaasUserMapper;
import com.shengyu.module.system.service.dept.DeptService;
import com.shengyu.module.system.service.dept.PostService;
import com.shengyu.module.system.service.permission.PermissionService;
import com.shengyu.module.system.service.tenant.TenantService;
import com.google.common.annotations.VisibleForTesting;
import java.io.InputStream;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 后台用户 Service 实现类
 *
 * @author 圣钰科技
 */
@Service("adminUserService")
@Slf4j
public class AdminUserServiceImpl implements AdminUserService {

    @Value("${sys.user.init-password:shengyukj}")
    private String userInitPassword;

    @Resource
    private AdminUserMapper userMapper;

    @Resource
    private SaasUserMapper saasUserMapper;

    @Resource
    private DeptService deptService;
    @Resource
    private PostService postService;
    @Resource
    private PermissionService permissionService;
    @Resource
    private PasswordEncoder passwordEncoder;
    @Resource
    @Lazy // 延迟，避免循环依赖报错
    private TenantService tenantService;

    @Resource
    private UserPostMapper userPostMapper;

    @Resource
    private FileApi fileApi;

    @Resource
    private MailSendApi mailSendApi;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createUser(UserSaveReqVO createReqVO) {
        // 校验账户配合
        tenantService.handleTenantInfo(tenant -> {
            long count = userMapper.selectCount();
            if (count >= tenant.getAccountCount()) {
                throw exception(USER_COUNT_MAX, tenant.getAccountCount());
            }
        });
        // 校验正确性
        validateUserForCreate(createReqVO.getUsername(),
            createReqVO.getMobile(), createReqVO.getDeptId(), createReqVO.getPostIds());
        // 插入用户
        AdminUserDO user = BeanUtils.toBean(createReqVO, AdminUserDO.class);
        //优先取邮箱账号的SaaS用户
        if (StrUtil.isNotBlank(createReqVO.getUsername())) {
            SaasUserDO userNameSaasDO = saasUserMapper.selectByUsername(createReqVO.getUsername());
            if (Objects.nonNull(userNameSaasDO)) {
                user.setSaasUserId(userNameSaasDO.getId());
            }
        } else {
            SaasUserDO mobileSaasDO = saasUserMapper.selectByMobile(createReqVO.getMobile());
            if (Objects.nonNull(mobileSaasDO)) {
                user.setSaasUserId(mobileSaasDO.getId());
            }
        }
        boolean registerSaasUser = Boolean.FALSE;
        String password = userInitPassword + (int)((Math.random() * 9 + 1) * Math.pow(10, 5));
        //如果还是空的话，就创建SaaS用户
        if (Objects.isNull(user.getSaasUserId())) {
            // 创建SaaS用户
            SaasUserDO saasUser = new SaasUserDO();
            if (StrUtil.isNotBlank(createReqVO.getUsername())) {
                saasUser.setUsername(createReqVO.getUsername());
            }
            if (StrUtil.isNotBlank(createReqVO.getMobile())) {
                saasUser.setMobile(createReqVO.getMobile());
            }
            saasUser.setDefaultTenant(TenantContextHolder.getTenantId());
            saasUser.setPassword(encodePassword(password));
            saasUserMapper.insert(saasUser);
            saasUser.setOpenId(StrUtils.uniqueId(saasUser.getId()));
            saasUserMapper.updateById(saasUser);
            // 插入用户
            user.setSaasUserId(saasUser.getId());
            registerSaasUser = Boolean.TRUE;
        }
        // 等待SaaS用户确认
        user.setStatus(CommonStatusEnum.AWAIT.getStatus());
        userMapper.insert(user);
        //添加时初次设置值
        user.setOpenAccount(StrUtils.uniqueId(user.getId()));
        userMapper.updateById(user);
        // 插入关联岗位
        if (CollectionUtil.isNotEmpty(user.getPostIds())) {
            userPostMapper.insertBatch(convertList(user.getPostIds(),
                postId -> new UserPostDO().setUserId(user.getId()).setPostId(postId)));
        }
        //是否是新注册的平台用户
        if (registerSaasUser) {
            Map<String, Object> mailParam = new HashMap<String, Object>();
            mailParam.put("mail", createReqVO.getUsername());
            mailParam.put("password", password);
            mailParam.put("registerTime", DateUtil.formatDateTime(new Date()));
            mailSendApi.sendSingleMail(createReqVO.getUsername(), null, UserTypeEnum.ADMIN.getValue(),
                "tenant-add-user", mailParam);
        }
        //todo 发送站内信通知SaaS用户确认被邀请
        return user.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createTenantUser(UserSaveReqVO createReqVO, AdminUserCreateReqDTO reqDTO) {
        // 校验账户配合
        tenantService.handleTenantInfo(tenant -> {
            long count = userMapper.selectCount();
            if (count >= tenant.getAccountCount()) {
                throw exception(USER_COUNT_MAX, tenant.getAccountCount());
            }
        });
        // 校验正确性
        validateUserForCreate(createReqVO.getUsername(),
            createReqVO.getMobile(), createReqVO.getDeptId(), createReqVO.getPostIds());
        // 插入用户
        AdminUserDO user = BeanUtils.toBean(createReqVO, AdminUserDO.class);
        //优先取邮箱账号的SaaS用户
        if (StrUtil.isNotBlank(createReqVO.getUsername())) {
            SaasUserDO userNameSaasDO = saasUserMapper.selectByUsername(createReqVO.getUsername());
            if (Objects.nonNull(userNameSaasDO)) {
                user.setSaasUserId(userNameSaasDO.getId());
            }
        } else {
            SaasUserDO mobileSaasDO = saasUserMapper.selectByMobile(createReqVO.getMobile());
            if (Objects.nonNull(mobileSaasDO)) {
                user.setSaasUserId(mobileSaasDO.getId());
            }
        }
        boolean registerSaasUser = Boolean.FALSE;
        String password = userInitPassword + (int)((Math.random() * 9 + 1) * Math.pow(10, 5));
        //如果还是空的话，就创建SaaS用户
        if (Objects.isNull(user.getSaasUserId())) {
            // 创建SaaS用户
            SaasUserDO saasUser = new SaasUserDO();
            if (StrUtil.isNotBlank(createReqVO.getUsername())) {
                saasUser.setUsername(createReqVO.getUsername());
            }
            if (StrUtil.isNotBlank(createReqVO.getMobile())) {
                saasUser.setMobile(createReqVO.getMobile());
            }
            saasUser.setDefaultTenant(TenantContextHolder.getTenantId());
            saasUser.setPassword(encodePassword(password));
            saasUserMapper.insert(saasUser);
            saasUser.setOpenId(StrUtils.uniqueId(saasUser.getId()));
            saasUserMapper.updateById(saasUser);
            // 插入用户
            user.setSaasUserId(saasUser.getId());
            registerSaasUser = Boolean.TRUE;
        }
        user.setStatus(CommonStatusEnum.ENABLE.getStatus());
        userMapper.insert(user);
        //添加时初次设置值
        user.setOpenAccount(StrUtils.uniqueId(user.getId()));
        userMapper.updateById(user);
        // 插入关联岗位
        if (CollectionUtil.isNotEmpty(user.getPostIds())) {
            userPostMapper.insertBatch(convertList(user.getPostIds(),
                postId -> new UserPostDO().setUserId(user.getId()).setPostId(postId)));
        }
        //是否时新注册的平台用户
        if (registerSaasUser) {
            Map<String, Object> mailParam = new HashMap<String, Object>();
            mailParam.put("mail", createReqVO.getUsername());
            mailParam.put("password", password);
            mailParam.put("registerTime", DateUtil.formatDateTime(new Date()));
            mailSendApi.sendSingleMail(createReqVO.getUsername(), null, UserTypeEnum.ADMIN.getValue(),
                "tenant-add-user", mailParam);
        }
        //todo 发送站内信通知SaaS用户确认被邀请
        return user.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateUser(UserUpdateReqVO updateReqVO) {
        // 校验正确性
        validateUserForUpdate(updateReqVO.getId(), updateReqVO.getDeptId(), updateReqVO.getPostIds());
        // 更新用户
        AdminUserDO updateObj = BeanUtils.toBean(updateReqVO, AdminUserDO.class);
        userMapper.updateById(updateObj);
        // 更新岗位
        updateUserPost(updateReqVO.getId(), updateObj);
    }

    private void updateUserPost(Long userId, AdminUserDO updateObj) {
        Set<Long> dbPostIds = convertSet(userPostMapper.selectListByUserId(userId), UserPostDO::getPostId);
        // 计算新增和删除的岗位编号
        Set<Long> postIds = CollUtil.emptyIfNull(updateObj.getPostIds());
        Collection<Long> createPostIds = CollUtil.subtract(postIds, dbPostIds);
        Collection<Long> deletePostIds = CollUtil.subtract(dbPostIds, postIds);
        // 执行新增和删除。对于已经授权的菜单，不用做任何处理
        if (!CollectionUtil.isEmpty(createPostIds)) {
            userPostMapper.insertBatch(convertList(createPostIds,
                postId -> new UserPostDO().setUserId(userId).setPostId(postId)));
        }
        if (!CollectionUtil.isEmpty(deletePostIds)) {
            userPostMapper.deleteByUserIdAndPostId(userId, deletePostIds);
        }
    }

    @Override
    public void updateUserLogin(Long id, String loginIp) {
        userMapper.updateById(new AdminUserDO().setId(id).setLoginIp(loginIp).setLoginDate(LocalDateTime.now()));
    }

    @Override
    public void updateUserProfile(Long id, UserProfileUpdateReqVO reqVO) {
        // 校验正确性
        AdminUserDO adminUserDO = validateAdminUserExists(id);
        // 执行更新
        userMapper.updateById(BeanUtils.toBean(reqVO, AdminUserDO.class).setId(id));
        // 执行更新
        SaasUserDO updateObj = new SaasUserDO().setId(adminUserDO.getSaasUserId());
        updateObj.setSex(reqVO.getSex());
        saasUserMapper.updateById(updateObj);
    }

    @Override
    public void updateUserPassword(Long id, UserProfileUpdatePasswordReqVO reqVO) {
        AdminUserDO adminUserDO = validateAdminUserExists(id);
        // 校验旧密码密码
        validateOldPassword(adminUserDO.getSaasUserId(), reqVO.getOldPassword());
        // 执行更新
        SaasUserDO updateObj = new SaasUserDO().setId(adminUserDO.getSaasUserId());
        // 加密密码
        updateObj.setPassword(encodePassword(reqVO.getNewPassword()));
        saasUserMapper.updateById(updateObj);
    }

    @Override
    public String updateUserAvatar(Long id, InputStream avatarFile) {
        validateAdminUserExists(id);
        // 存储文件
        String avatar = fileApi.createFile(IoUtil.readBytes(avatarFile));
        // 更新路径
        AdminUserDO sysUserDO = new AdminUserDO();
        sysUserDO.setId(id);
        sysUserDO.setAvatar(avatar);
        userMapper.updateById(sysUserDO);
        return avatar;
    }

    @Override
    public void updateUserPassword(Long id, String password) {
        // 校验用户存在
        validateUserExists(id);
        AdminUserDO user = userMapper.selectById(id);
        // 更新密码
        SaasUserDO updateObj = new SaasUserDO();
        updateObj.setId(user.getSaasUserId());
        updateObj.setPassword(encodePassword(password)); // 加密密码
        saasUserMapper.updateById(updateObj);
    }

    @Override
    public void updateUserStatus(Long id, Integer status) {
        // 校验用户存在
        validateUserExists(id);
        // 更新状态
        AdminUserDO updateObj = new AdminUserDO();
        updateObj.setId(id);
        updateObj.setStatus(status);
        userMapper.updateById(updateObj);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteUser(Long id) {
        // 校验用户存在
        validateUserExists(id);
        // 删除用户
        userMapper.deleteById(id);
        // 删除用户关联数据
        permissionService.processUserDeleted(id);
        // 删除用户岗位
        userPostMapper.deleteByUserId(id);
    }

    @Override
    public AdminUserDO getUserBySaasUserId(Long saasUserId) {
        return userMapper.selectBySaasUserId(saasUserId);
    }

    @Override
    public PageResult<UserRespVO> getUserPage(UserPageReqVO reqVO) {
        return userMapper.selectJoinPage(reqVO, getDeptCondition(reqVO.getDeptId()));
    }

    @Override
    public UserRespVO getUser(Long id) {
        return userMapper.selectJoinOne(id);
    }

    @Override
    public List<AdminUserDO> getUserListByDeptIds(Collection<Long> deptIds) {
        if (CollUtil.isEmpty(deptIds)) {
            return Collections.emptyList();
        }
        return userMapper.selectListByDeptIds(deptIds);
    }

    @Override
    public List<AdminUserDO> getUserListByPostIds(Collection<Long> postIds) {
        if (CollUtil.isEmpty(postIds)) {
            return Collections.emptyList();
        }
        Set<Long> userIds = convertSet(userPostMapper.selectListByPostIds(postIds), UserPostDO::getUserId);
        if (CollUtil.isEmpty(userIds)) {
            return Collections.emptyList();
        }
        return userMapper.selectBatchIds(userIds);
    }

    @Override
    public List<AdminUserDO> getUserList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return Collections.emptyList();
        }
        return userMapper.selectBatchIds(ids);
    }

    @Override
    public void validateUserList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return;
        }
        // 获得岗位信息
        List<AdminUserDO> users = userMapper.selectBatchIds(ids);
        Map<Long, AdminUserDO> userMap = CollectionUtils.convertMap(users, AdminUserDO::getId);
        // 校验
        ids.forEach(id -> {
            AdminUserDO user = userMap.get(id);
            if (user == null) {
                throw exception(USER_NOT_EXISTS);
            }
            if (!CommonStatusEnum.ENABLE.getStatus().equals(user.getStatus())) {
                throw exception(USER_IS_DISABLE, user.getNickname());
            }
        });
    }

    @Override
    public List<AdminUserDO> getUserListByNickname(String nickname) {
        return userMapper.selectListByNickname(nickname);
    }

    /**
     * 获得部门条件：查询指定部门的子部门编号们，包括自身
     * @param deptId 部门编号
     * @return 部门编号集合
     */
    private Set<Long> getDeptCondition(Long deptId) {
        if (deptId == null) {
            return Collections.emptySet();
        }
        Set<Long> deptIds = convertSet(deptService.getChildDeptList(deptId), DeptDO::getId);
        // 包括自身
        deptIds.add(deptId);
        return deptIds;
    }

    /**
     * 新增时的校验
     * @param username SaaS用户表的邮箱账号
     * @param mobile SaaS表的手机号
     * @param deptId 部门编号
     * @param postIds 多个岗位编号
     */
    private void validateUserForCreate(String username, String mobile,
        Long deptId, Set<Long> postIds) {
        // 关闭数据权限，避免因为没有数据权限，查询不到数据，进而导致唯一校验不正确
        DataPermissionUtils.executeIgnore(() -> {
            // 校验邮箱账号在SaaS用户表中是否存在,以及是否被其它账号绑定了
            validateUsernameExists(username, mobile);
            // 校验部门处于开启状态
            deptService.validateDeptList(CollectionUtils.singleton(deptId));
            // 校验岗位处于开启状态
            postService.validatePostList(postIds);
        });
    }

    private void validateUserForUpdate(Long id, Long deptId, Set<Long> postIds) {
        // 关闭数据权限，避免因为没有数据权限，查询不到数据，进而导致唯一校验不正确
        DataPermissionUtils.executeIgnore(() -> {
            // 校验用户存在
            validateUserExists(id);
            // 校验部门处于开启状态
            deptService.validateDeptList(CollectionUtils.singleton(deptId));
            // 校验岗位处于开启状态
            postService.validatePostList(postIds);
        });
    }

    @VisibleForTesting
    void validateUserExists(Long id) {
        if (id == null) {
            return;
        }
        AdminUserDO user = userMapper.selectById(id);
        if (user == null) {
            throw exception(USER_NOT_EXISTS);
        }
        // 校验账户配合
        tenantService.handleTenantInfo(tenant -> {
            if (id.equals(tenant.getContactUserId())) {
                throw exception(USER_ADMIN);
            }
        });
    }

    /**
     * 一般用于自己操作自己
     * @param id 用户id
     */
    @VisibleForTesting
    AdminUserDO validateAdminUserExists(Long id) {
        if (id == null) {
            return null;
        }
        AdminUserDO user = userMapper.selectById(id);
        if (user == null) {
            throw exception(USER_NOT_EXISTS);
        }
        return user;
    }

    /**
     * 校验邮箱账号在SaaS用户表中是否存在,以及是否被其它账号绑定了
     * @param username saas用户表中的邮箱账号
     * @param mobile saas用户表中的手机号
     */
    @VisibleForTesting
    void validateUsernameExists(String username, String mobile) {
        //校验是否存在
        if (StrUtil.isAllBlank(username, mobile)) {
            throw exception(USER_CREATE_SAAS_EXISTS);
        }
        if (StrUtil.isNotBlank(username)) {
            SaasUserDO userNameSaasDO = saasUserMapper.selectByUsername(username);
            if (Objects.nonNull(userNameSaasDO)) {
                //校验是否被其它账号已绑定
                validateSaasUserIdUnique(userNameSaasDO.getId());
            }
        }
        if (StrUtil.isNotBlank(mobile)) {
            SaasUserDO mobileSaasDO = saasUserMapper.selectByMobile(mobile);
            if (Objects.nonNull(mobileSaasDO)) {
                //校验是否被其它账号已绑定
                validateSaasUserIdUnique(mobileSaasDO.getId());
            }
        }
    }

    /**
     * 校验当前SaaS体系用户是否被其它用户绑定
     * @param saasUserId SaaS体系用户id
     */
    @VisibleForTesting
    void validateSaasUserIdUnique(Long saasUserId) {
        if (saasUserId == null) {
            return;
        }
        AdminUserDO user = userMapper.selectBySaasUserId(saasUserId);
        if (user == null) {
            return;
        }
        throw exception(USER_SAAS_ID_UNIQUE, user.getNickname());
    }

    /**
     * 校验旧密码
     * @param id          用户 id
     * @param oldPassword 旧密码
     */
    @VisibleForTesting
    void validateOldPassword(Long id, String oldPassword) {
        SaasUserDO user = saasUserMapper.selectById(id);
        if (user == null) {
            throw exception(USER_NOT_EXISTS);
        }
        if (!isPasswordMatch(oldPassword, user.getPassword())) {
            throw exception(USER_PASSWORD_FAILED);
        }
    }

//    @Override
//    @Transactional(rollbackFor = Exception.class) // 添加事务，异常则回滚所有导入
//    public UserImportRespVO importUserList(List<UserImportExcelVO> importUsers, boolean isUpdateSupport) {
//        if (CollUtil.isEmpty(importUsers)) {
//            throw exception(USER_IMPORT_LIST_IS_EMPTY);
//        }
//        UserImportRespVO respVO = UserImportRespVO.builder().createUsernames(new ArrayList<>())
//                .updateUsernames(new ArrayList<>()).failureUsernames(new LinkedHashMap<>()).build();
//        importUsers.forEach(importUser -> {
//            // 校验，判断是否有不符合的原因
//            try {
//                validateUserForCreateOrUpdate(null, null, importUser.getMobile(), importUser.getEmail(),
//                        importUser.getDeptId(), null);
//            } catch (ServiceException ex) {
//                respVO.getFailureUsernames().put(importUser.getUsername(), ex.getMessage());
//                return;
//            }
//            // 判断如果不存在，在进行插入
//            AdminUserDO existUser = userMapper.selectByUsername(importUser.getUsername());
//            if (existUser == null) {
//                userMapper.insert(BeanUtils.toBean(importUser, AdminUserDO.class)
//                        .setPassword(encodePassword(userInitPassword)).setPostIds(new HashSet<>())); // 设置默认密码及空岗位编号数组
//                respVO.getCreateUsernames().add(importUser.getUsername());
//                return;
//            }
//            // 如果存在，判断是否允许更新
//            if (!isUpdateSupport) {
//                respVO.getFailureUsernames().put(importUser.getUsername(), USER_USERNAME_EXISTS.getMsg());
//                return;
//            }
//            AdminUserDO updateUser = BeanUtils.toBean(importUser, AdminUserDO.class);
//            updateUser.setId(existUser.getId());
//            userMapper.updateById(updateUser);
//            respVO.getUpdateUsernames().add(importUser.getUsername());
//        });
//        return respVO;
//    }

    @Override
    public List<AdminUserDO> getUserListByStatus(Integer status) {
        return userMapper.selectListByStatus(status);
    }

    @Override
    public boolean isPasswordMatch(String rawPassword, String encodedPassword) {
        return passwordEncoder.matches(rawPassword, encodedPassword);
    }

    @Override
    public List<MyTenantRespVO> getMyTenantList() {
        AdminUserDO user = userMapper.selectById(getLoginUserId());
        if (user == null) {
            return Collections.emptyList();
        }
        List<MyTenantRespVO> tenantList = new ArrayList<>();
        //忽略多租户进行查询
        TenantUtils.executeIgnore(() -> {
            // 关闭数据权限，避免因为没有数据权限，查询不到数据
            DataPermissionUtils.executeIgnore(() -> {
                List<AdminUserDO> userDOList = userMapper.selectList(AdminUserDO::getSaasUserId, user.getSaasUserId());
                for (AdminUserDO userDO : userDOList) {
                    MyTenantRespVO tenant = new MyTenantRespVO();
                    TenantRespDTO tenantRespDTO = tenantService.getTenantById(userDO.getTenantId());
                    if (Objects.isNull(tenantRespDTO)) {
                        continue;
                    }
                    tenant.setId(tenantRespDTO.getId());
                    tenant.setTenantName(tenantRespDTO.getName());
                    tenant.setStatus(CommonStatusEnum.isEnable(tenantRespDTO.getStatus())? "正常" : "禁用");
                    tenant.setLoginDate(userDO.getLoginDate());
                    tenantList.add(tenant);
                }
            });
        });
        return tenantList;
    }

    /**
     * 对密码进行加密
     *
     * @param password 密码
     * @return 加密后的密码
     */
    private String encodePassword(String password) {
        return passwordEncoder.encode(password);
    }

}