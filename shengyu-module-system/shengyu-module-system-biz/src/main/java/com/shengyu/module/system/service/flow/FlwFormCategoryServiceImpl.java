package com.shengyu.module.system.service.flow;

import com.shengyu.module.system.dal.dataobject.flow.FlwFormCategory;
import com.shengyu.module.system.controller.admin.flow.vo.FlwFormCategoryVO;
import com.shengyu.module.system.dal.mysql.flow.FlwFormCategoryMapper;
import com.shengyu.module.system.service.flow.IFlwFormCategoryService;
import com.shengyu.module.system.service.flow.IFlwFormTemplateService;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.aizuda.service.service.BaseServiceImpl;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Objects;

/**
 * 流程表单分类 服务实现类
 *
 * @author hubin
 * @since 2024-05-19
 */
@Service
@AllArgsConstructor
public class FlwFormCategoryServiceImpl extends BaseServiceImpl<FlwFormCategoryMapper, FlwFormCategory> implements IFlwFormCategoryService {
    private IFlwFormTemplateService formTemplateService;

    @Override
    public Page<FlwFormCategory> page(Page<FlwFormCategory> page, FlwFormCategory flwFormCategory) {
        LambdaQueryWrapper<FlwFormCategory> lqw = Wrappers.lambdaQuery(flwFormCategory);
        return super.page(page, lqw);
    }

    @Override
    public List<FlwFormCategoryVO> listTree(FlwFormCategory flwFormCategory) {
        List<FlwFormCategory> sysDepartmentList = super.list(Wrappers.lambdaQuery(flwFormCategory));
        if (CollectionUtils.isEmpty(sysDepartmentList)) {
            return Collections.emptyList();
        }
        return sysDepartmentList.stream().filter(e -> Objects.equals(0L, e.getPid())).map(e -> {
            FlwFormCategoryVO vo = e.convert(FlwFormCategoryVO.class);
            vo.setChildren(this.getChild(vo.getId(), vo.getName(), sysDepartmentList));
            return vo;
        }).toList();
    }

    /**
     * 获取子节点
     */
    private List<FlwFormCategoryVO> getChild(Long id, String parentName, List<FlwFormCategory> flwFormCategoryList) {
        // 遍历所有节点，将所有表单分类的父id与传过来的根节点的id比较
        List<FlwFormCategory> childList = flwFormCategoryList.stream().filter(e -> Objects.equals(id, e.getPid())).toList();
        if (childList.isEmpty()) {
            // 没有子节点，返回一个空 List（递归退出）
            return null;
        }
        // 递归
        return childList.stream().map(e -> {
            FlwFormCategoryVO vo = e.convert(FlwFormCategoryVO.class);
            vo.setParentName(parentName);
            vo.setChildren(this.getChild(vo.getId(), vo.getName(), flwFormCategoryList));
            return vo;
        }).toList();
    }

    @Override
    public List<FlwFormCategory> listAll() {
        return super.list();
    }

    @Override
    public boolean updateById(FlwFormCategory flwFormCategory) {
        ServiceExceptionUtil.isEmpty(flwFormCategory.getId(), "主键不存在无法更新");
        List<Long> ids = baseMapper.selectIdsRecursive(flwFormCategory.getId());
        ServiceExceptionUtil.fail(CollectionUtils.isNotEmpty(ids) && ids.contains(flwFormCategory.getPid()),
                "父分类不能为子分类，请重新选择父分类");
        if (null == flwFormCategory.getPid()) {
            // 未设置父ID设置为0
            flwFormCategory.setPid(0L);
        }
        return super.updateById(flwFormCategory);
    }

    @Override
    public boolean removeByIds(List<Long> ids) {
        ServiceExceptionUtil.fail(ids.stream().anyMatch(Objects::isNull), "不允许删除所有");
        this.checkExists(Wrappers.<FlwFormCategory>lambdaQuery().select(FlwFormCategory::getId)
                .in(FlwFormCategory::getPid, ids), "存在子类不允许删除");
        ServiceExceptionUtil.fail(formTemplateService.existByFormCategoryIds(ids), "存在关联表单模板不允许删除");
        return super.removeByIds(ids);
    }
}
