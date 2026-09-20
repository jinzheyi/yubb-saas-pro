import type { App } from 'vue'
import { useUserStoreWithOut } from '@/store/modules/user'

const { t } = useI18n() // 国际化

/** 判断权限的指令 directive */
export function hasPermi(app: App<Element>) {
  app.directive('hasPermi', (el, binding) => {
    const { value } = binding

    if (value && value instanceof Array && value.length > 0) {
      const hasPermissions = hasPermission(value)

      if (!hasPermissions) {
        el.parentNode && el.parentNode.removeChild(el)
      }
    } else {
      throw new Error(t('permission.hasPermission'))
    }
  })
}

/** 判断权限的方法 function */
const all_permission = '*:*:*'
export const hasPermission = (permission: string[]) => {
  // 指令模块会在 main.ts 初始化阶段被导入；此时 app 尚未 app.use(pinia)。
  // 使用显式 pinia 实例，避免冷启动时触发 getActivePinia 异常。
  const userStore = useUserStoreWithOut()
  return (
    userStore.permissions.has(all_permission) ||
    permission.some((permission) => userStore.permissions.has(permission))
  )
}
