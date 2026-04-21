import { defineStore } from 'pinia'
import { store } from '../index'
import zhCn from 'element-plus/es/locale/lang/zh-cn'
import en from 'element-plus/es/locale/lang/en'
import { CACHE_KEY, useCache } from '@/hooks/web/useCache'
import { LocaleDropdownType } from '@/types/localeDropdown'

const { wsCache } = useCache()

const elLocaleMap = {
  'zh-CN': zhCn,
  en: en
}
interface LocaleState {
  currentLocale: LocaleDropdownType
  localeMap: LocaleDropdownType[]
}

const resolveBrowserLocale = (): LocaleType => {
  if (typeof window !== 'undefined') {
    const language = window.navigator.language || 'zh-CN'
    if (language.toLowerCase().startsWith('en')) {
      return 'en'
    }
  }
  return 'zh-CN'
}

export const useLocaleStore = defineStore('locales', {
  state: (): LocaleState => {
    const cachedLang = wsCache.get(CACHE_KEY.LANG) || resolveBrowserLocale()
    return {
      currentLocale: {
        lang: cachedLang,
        elLocale: elLocaleMap[cachedLang]
      },
      // 多语言
      localeMap: [
        {
          lang: 'zh-CN',
          name: '简体中文'
        },
        {
          lang: 'en',
          name: 'English'
        }
      ]
    }
  },
  getters: {
    getCurrentLocale(): LocaleDropdownType {
      return this.currentLocale
    },
    getLocaleMap(): LocaleDropdownType[] {
      return this.localeMap
    }
  },
  actions: {
    setCurrentLocale(localeMap: LocaleDropdownType) {
      // this.locale = Object.assign(this.locale, localeMap)
      this.currentLocale.lang = localeMap?.lang
      this.currentLocale.elLocale = elLocaleMap[localeMap?.lang]
      wsCache.set(CACHE_KEY.LANG, localeMap?.lang)
    },
    setCurrentLang(lang: LocaleType) {
      this.currentLocale.lang = lang
      this.currentLocale.elLocale = elLocaleMap[lang]
      wsCache.set(CACHE_KEY.LANG, lang)
    }
  }
})

export const useLocaleStoreWithOut = () => {
  return useLocaleStore(store)
}
