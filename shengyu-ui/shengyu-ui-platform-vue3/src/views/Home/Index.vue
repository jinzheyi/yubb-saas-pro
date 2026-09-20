<template>
  <main class="workbench platform-workbench">
    <section class="command-hero">
      <div class="command-grid"></div>
      <div class="command-copy"><span class="eyebrow"><Icon icon="ep:cpu" /> PLATFORM COMMAND</span><h1>平台运行一切就绪。</h1><p>从真实租户、成员与在线态，快速掌握今天的运营脉搏。</p></div>
      <div v-if="hasPlatformUserAccess || hasTenantAccess" class="online-cluster"><div><span class="online-ring"><Icon icon="ep:connection" /></span><b>{{ visibleOnlineCount }}</b><small>当前在线</small></div><div class="online-breakdown"><span v-if="hasPlatformUserAccess"><i class="platform-dot"></i>平台 {{ overview.platformOnlineCount }}</span><span v-if="hasTenantAccess"><i class="tenant-dot"></i>租户 {{ overview.tenantOnlineCount }}</span></div></div>
    </section>

    <section v-if="metrics.length" class="metric-grid" v-loading="loading">
      <article v-for="metric in metrics" :key="metric.label" class="metric-card" @click="go(metric.path)">
        <span :class="['metric-icon', metric.tone]"><Icon :icon="metric.icon" /></span><div><p>{{ metric.label }}</p><strong>{{ metric.value }}</strong><small>{{ metric.note }}</small></div><Icon class="metric-arrow" icon="ep:arrow-up-right" />
      </article>
    </section>

    <section v-if="hasTenantAccess || hasNoticeAccess" :class="['dashboard-grid', { 'dashboard-grid--single': !hasTenantAccess }]">
      <article v-if="hasTenantAccess" class="tenant-panel panel" v-loading="loading">
        <header><div><span class="panel-kicker">TENANT RADAR</span><h2>新增租户</h2></div><button type="button" class="text-action" @click="go('/system/tenant/list')">进入租户列表 <Icon icon="ep:arrow-right" /></button></header>
        <div v-if="overview.recentTenants.length" class="tenant-list"><button v-for="tenant in overview.recentTenants" :key="tenant.id" type="button" class="tenant-row" @click="go('/system/tenant/list')"><span class="tenant-avatar">{{ tenant.name.slice(0, 1) }}</span><span class="tenant-name"><b>{{ tenant.name }}</b><small>创建于 {{ date(tenant.createTime) }}</small></span><span class="tenant-status" :class="tenant.expireTime ? '' : 'healthy'">{{ tenant.expireTime ? '已配置期限' : '长期有效' }}</span><Icon icon="ep:arrow-right" /></button></div>
        <div v-else class="empty-state"><Icon icon="ep:office-building" /><span>暂未创建租户</span></div>
      </article>
      <aside :class="['side-stack', { 'side-stack--solo': !hasTenantAccess }]">
        <article v-if="hasTenantAccess" class="panel insight-panel"><span class="panel-kicker">AI READY</span><div class="insight-top"><span class="insight-icon"><Icon icon="ep:magic-stick" /></span><div><h2>运营洞察准备中</h2><p>真实数据已接入，后续可直接启用 AI 运营建议。</p></div></div><div class="signal-row"><span>租户启用率</span><b>{{ activationRate }}%</b></div><div class="progress"><i :style="{ width: `${activationRate}%` }"></i></div></article>
        <article v-if="hasNoticeAccess" class="panel notice-panel" v-loading="loading"><header><div><span class="panel-kicker">BROADCAST</span><h2>平台公告</h2></div><button type="button" class="text-action" @click="go('/system/notice')">全部</button></header><button v-for="notice in overview.recentNotices.slice(0, 2)" :key="notice.id" type="button" class="notice-row" @click="go('/system/notice')"><span></span><b>{{ notice.title }}</b><small>{{ date(notice.createTime) }}</small></button><div v-if="!overview.recentNotices.length" class="notice-empty">暂无新公告</div></article>
      </aside>
    </section>
  </main>
</template>

<script lang="ts" setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/store/modules/user'
import { getPlatformDashboardOverview, type PlatformDashboardOverview } from '@/api/dashboard'

const router = useRouter()
const userStore = useUserStore()
const loading = ref(false)
const overview = reactive<PlatformDashboardOverview>({ tenantCount: 0, enabledTenantCount: 0, tenantUserCount: 0, platformUserCount: 0, platformOnlineCount: 0, tenantOnlineCount: 0, recentTenants: [], recentNotices: [] })
const activationRate = computed(() => overview.tenantCount ? Math.round(overview.enabledTenantCount / overview.tenantCount * 100) : 0)
const can = (permission: string) => userStore.getPermissions.includes('*:*:*') || userStore.getPermissions.includes(permission)
const hasTenantAccess = computed(() => can('system:tenant:query'))
const hasPlatformUserAccess = computed(() => can('system:user:query'))
const hasNoticeAccess = computed(() => can('system:notice:query'))
const visibleOnlineCount = computed(() => (hasPlatformUserAccess.value ? overview.platformOnlineCount : 0) + (hasTenantAccess.value ? overview.tenantOnlineCount : 0))
const metrics = computed(() => [
  { label: '全部租户', value: overview.tenantCount, note: `${overview.enabledTenantCount} 个正在启用`, icon: 'ep:office-building', tone: 'blue', path: '/system/tenant/list', visible: hasTenantAccess.value },
  { label: '租户实际成员', value: overview.tenantUserCount, note: '不含套餐账号额度', icon: 'ep:user-filled', tone: 'violet', path: '/system/tenant/list', visible: hasTenantAccess.value },
  { label: '平台管理员', value: overview.platformUserCount, note: `${overview.platformOnlineCount} 人当前在线`, icon: 'ep:avatar', tone: 'mint', path: '/system/user', visible: hasPlatformUserAccess.value },
  { label: '租户在线人数', value: overview.tenantOnlineCount, note: '按活跃用户去重', icon: 'ep:connection', tone: 'amber', path: '/system/tenant/list', visible: hasTenantAccess.value }
].filter((metric) => metric.visible))
const go = (path: string) => router.push(path)
const date = (value?: string | number) => {
  if (!value) return '—'
  if (typeof value === 'string') return value.slice(0, 10).replaceAll('-', '.')
  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) return '—'
  return `${parsed.getFullYear()}.${String(parsed.getMonth() + 1).padStart(2, '0')}.${String(parsed.getDate()).padStart(2, '0')}`
}
onMounted(async () => { loading.value = true; try { Object.assign(overview, await getPlatformDashboardOverview()) } finally { loading.value = false } })
</script>

<style lang="scss" scoped>
.workbench{--ink:#18223c;--muted:#79849a;max-width:1440px;margin:0 auto;padding:4px 4px 30px;color:var(--ink)}.command-hero{position:relative;overflow:hidden;display:flex;align-items:center;justify-content:space-between;min-height:202px;padding:34px 42px;border-radius:22px;background:linear-gradient(112deg,#0f1c48,#253990 55%,#3757d4);box-shadow:0 19px 42px rgba(24,49,127,.22);color:#fff}.command-grid{position:absolute;inset:0;background-image:linear-gradient(rgba(255,255,255,.06) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.06) 1px,transparent 1px);background-size:28px 28px;mask-image:linear-gradient(90deg,transparent 20%,#000 80%)}.command-copy,.online-cluster{position:relative;z-index:1}.eyebrow,.panel-kicker{font-size:10px;font-weight:800;letter-spacing:1.3px}.eyebrow{display:flex;align-items:center;gap:6px;color:#aebcff}.command-copy h1{margin:10px 0 6px;font-size:29px;letter-spacing:-.6px}.command-copy p{margin:0;color:#c5cef5}.online-cluster{display:flex;align-items:center;gap:18px;padding:17px 22px;border:1px solid rgba(255,255,255,.16);border-radius:17px;background:rgba(7,18,64,.26);backdrop-filter:blur(11px)}.online-cluster>div:first-child{display:grid;grid-template-columns:45px auto;column-gap:9px}.online-ring{grid-row:span 2;display:grid;place-items:center;width:43px;height:43px;border-radius:50%;background:rgba(127,218,255,.2);color:#9fe7ff;font-size:20px}.online-cluster b{font-size:23px;line-height:1}.online-cluster small{font-size:11px;color:#bdc8ef}.online-breakdown{display:grid;gap:7px;padding-left:17px;border-left:1px solid rgba(255,255,255,.15);font-size:12px;color:#e4e9ff}.online-breakdown i{display:inline-block;width:6px;height:6px;margin-right:5px;border-radius:50%}.platform-dot{background:#8dd8ff}.tenant-dot{background:#9bf1bd}.metric-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:15px;margin:18px 0}.metric-card{position:relative;display:flex;align-items:center;gap:13px;min-height:116px;padding:18px;border:1px solid #e8ecf5;border-radius:17px;background:#fff;box-shadow:0 7px 18px rgba(30,41,80,.045);cursor:pointer;transition:.25s ease}.metric-card:hover{transform:translateY(-3px);box-shadow:0 14px 27px rgba(31,50,111,.12)}.metric-icon{display:grid;place-items:center;width:43px;height:43px;border-radius:13px;font-size:20px}.blue{background:#e8f1ff;color:#3575df}.violet{background:#efecff;color:#6759df}.mint{background:#e5f9ef;color:#16a470}.amber{background:#fff3df;color:#e9931e}.metric-card p,.metric-card small{display:block;margin:0;color:var(--muted);font-size:11px}.metric-card strong{display:block;margin:4px 0;font-size:25px;letter-spacing:-.5px}.metric-arrow{position:absolute;right:15px;top:15px;color:#aeb7c8}.dashboard-grid{display:grid;grid-template-columns:1.45fr .9fr;gap:18px}.panel{padding:23px;border:1px solid #e8ecf5;border-radius:19px;background:#fff;box-shadow:0 7px 18px rgba(30,41,80,.04)}.panel header{display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:14px}.panel-kicker{color:#7670e8}.panel h2{margin:4px 0 0;font-size:17px}.text-action{display:flex;align-items:center;gap:3px;border:0;background:none;color:#594fe8;font-size:12px;cursor:pointer}.tenant-list{display:grid}.tenant-row{display:flex;align-items:center;gap:12px;width:100%;padding:11px 0;border:0;border-bottom:1px solid #f0f2f7;background:none;color:inherit;text-align:left;cursor:pointer}.tenant-row:last-child{border:0}.tenant-row:hover b{color:#554be2}.tenant-avatar{display:grid;place-items:center;width:34px;height:34px;border-radius:11px;background:linear-gradient(135deg,#e7e5ff,#f3f1ff);color:#5e55df;font-size:14px;font-weight:800}.tenant-name{flex:1;min-width:0}.tenant-name b{display:block;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:13px}.tenant-name small{display:block;margin-top:4px;color:#9aa4b7;font-size:11px}.tenant-status{padding:4px 7px;border-radius:6px;background:#fff3e5;color:#bd7a1c;font-size:10px}.tenant-status.healthy{background:#e8f8ef;color:#258b60}.tenant-row>svg{color:#a9b2c2}.side-stack{display:grid;gap:18px}.insight-panel{background:linear-gradient(135deg,#fbfaff,#f5f7ff)}.insight-top{display:flex;align-items:center;gap:11px;margin-top:13px}.insight-icon{display:grid;place-items:center;width:38px;height:38px;border-radius:12px;background:#eae8ff;color:#675ce4;font-size:19px}.insight-top h2{font-size:14px}.insight-top p{margin:5px 0 0;color:#8892a8;font-size:11px;line-height:1.45}.signal-row{display:flex;justify-content:space-between;margin-top:17px;color:#758096;font-size:12px}.signal-row b{color:#4f46db}.progress{height:6px;margin-top:8px;border-radius:9px;background:#e5e8fa;overflow:hidden}.progress i{display:block;height:100%;border-radius:inherit;background:linear-gradient(90deg,#6960eb,#8b8aff);transition:width .7s ease}.notice-panel{min-height:151px}.notice-row{display:grid;grid-template-columns:7px 1fr auto;align-items:center;gap:7px;width:100%;padding:8px 0;border:0;background:none;text-align:left;cursor:pointer}.notice-row span{width:6px;height:6px;border-radius:50%;background:#746ceb}.notice-row b{overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:12px;font-weight:600;color:#455069}.notice-row small{color:#9ca6b8;font-size:10px}.notice-empty{padding:13px 0;color:#a4adbd;font-size:12px}.empty-state{display:grid;place-items:center;gap:7px;height:160px;color:#a3acbd;font-size:13px}.empty-state svg{font-size:25px}@media(max-width:1050px){.metric-grid{grid-template-columns:repeat(2,1fr)}.dashboard-grid{grid-template-columns:1fr}.side-stack{grid-template-columns:1fr 1fr}}@media(max-width:680px){.workbench{padding:0}.command-hero{min-height:170px;padding:27px}.command-copy h1{font-size:23px}.online-cluster{display:none}.metric-grid{grid-template-columns:1fr;gap:10px}.side-stack{grid-template-columns:1fr}.tenant-status{display:none}}
.dashboard-grid--single{grid-template-columns:1fr}.side-stack--solo{grid-template-columns:1fr}

:global(html.dark) .platform-workbench{--ink:var(--el-text-color-primary);--muted:var(--el-text-color-secondary)}
:global(html.dark) .platform-workbench .metric-card,:global(html.dark) .platform-workbench .panel{background:var(--el-bg-color);border-color:rgba(255,255,255,.08);box-shadow:0 10px 24px rgba(0,0,0,.16)}
:global(html.dark) .platform-workbench .metric-card:hover{background:var(--el-fill-color-light);box-shadow:0 15px 30px rgba(0,0,0,.25)}
:global(html.dark) .platform-workbench .insight-panel{background:linear-gradient(135deg,#1d2341,#171d35)}
:global(html.dark) .platform-workbench .tenant-row{border-bottom-color:rgba(255,255,255,.07)}
:global(html.dark) .platform-workbench .tenant-row:hover{background:var(--el-fill-color-light)}
:global(html.dark) .platform-workbench .tenant-name b,:global(html.dark) .platform-workbench .notice-row b{color:var(--el-text-color-primary)}
:global(html.dark) .platform-workbench .tenant-name small,:global(html.dark) .platform-workbench .notice-row small,:global(html.dark) .platform-workbench .insight-top p,:global(html.dark) .platform-workbench .empty-state,:global(html.dark) .platform-workbench .notice-empty{color:var(--el-text-color-secondary)}
:global(html.dark) .platform-workbench .blue{background:#16294e;color:#74a8ff}:global(html.dark) .platform-workbench .violet{background:#29234e;color:#aaa1ff}:global(html.dark) .platform-workbench .mint{background:#153b35;color:#5fddad}:global(html.dark) .platform-workbench .amber{background:#472f16;color:#ffbf63}
:global(html.dark) .platform-workbench .tenant-avatar{background:linear-gradient(135deg,#282554,#1e2543);color:#b3aeff}:global(html.dark) .platform-workbench .tenant-status{background:#452d17;color:#ffc36a}:global(html.dark) .platform-workbench .tenant-status.healthy{background:#163a31;color:#69d9ae}:global(html.dark) .platform-workbench .progress{background:#303956}
</style>
