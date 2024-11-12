<p align="center">
 <img src="https://img.shields.io/badge/Spring%20Boot-2.7.17-blue.svg" alt="Downloads">
 <img src="https://img.shields.io/badge/Vue-3.2-blue.svg" alt="Downloads">
</p>

如果这个项目让你有所收获，记得 Star 关注哦，这对我是非常不错的鼓励与支持。

# 本系统基于芋道开源系统进行魔改（已联系作者，不存在侵权）

# 作者博客地址：http://blog.shengyukj.top/ 里面有该项目的详细部署教程+相关SaaS业务介绍（博客文章在持续补充中......）

# 部署文档地址：http://blog.shengyukj.top/article/178

# 以下是商业版功能脑图规划（不是最终版，不定期更新）
![圣钰SaaS.png](https://zhushuyong.oss-cn-hangzhou.aliyuncs.com/images/20220819/6376c21a82ea44a0823bc10e4ed4caea.png?x-oss-process=image/auto-orient,1/interlace,1/quality,q_50/format,jpg/watermark,text_5pyx6L-w5YuHLXpodXNodXlvbmc,color_ff0021,size_18,x_10,y_10)

## 演示
### 商用pro版本演示

**商用pro版的插件功能架构体系已经实现**

[平台登录地址:http://saasadmin.shengyukj.top](http://saasadmin.shengyukj.top)

test/123456  (平台端体验账号)

[租户登录地址:http://saas.shengyukj.top](http://saas.shengyukj.top)

jin_zheyicn@qq.com/shengyukj578503

![输入图片说明](image.png)

<font color='blue'> 更多租户可以在平台系统端进行添加，维护。所有的租户数据完全隔离 </font>

# 其它更多资料待发布之日公布更新


# 圣钰SaaS钉钉版规划

1、用户登录判断是否账号存在，注册完成提示：

- 创建企业（租户）
- 加入其它企业

2、用户登录，默认登录上一次登录的租户，系统会记录一个默认租户。用户进入系统后，左侧右上角有选择多租户切换（如果只有只有租户则切换操作隐藏）

3、每个租户的用户体系、角色体系、插件订阅体系、业务数据体系完全独立，控制单元与业务剥离。具体用户体系仿钉钉/飞书/企微 等

4、设计上是有一个独立的SaaS用户表，作为登录用户的存储。以及租户用户表，作为隔离用户体系

5、变更为钉钉多租户多用户模式后，短信相关配置、三方登录相关配置需要转移到平台来统一控制。不能兼容各个租户都有一套配置
