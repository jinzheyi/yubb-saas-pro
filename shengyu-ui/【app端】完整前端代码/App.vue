<script>
	export default {
		onLaunch: function() {
			// #ifdef APP-PLUS-NVUE
			// 加载公共图标库
			const domModule = weex.requireModule('dom')
			domModule.addRule('fontFace', {
			    'fontFamily': "iconfont",
			    'src': "url('https://at.alicdn.com/t/font_1365296_2ijcbdrmsg.ttf')"
			});
			// #endif
			// 初始化录音管理器
			this.$store.commit('initRECORD')
			// 初始化登录状态
			this.$store.dispatch('initLogin')
			console.log('App Launch')
			// 监听键盘高度变化
			uni.onKeyboardHeightChange(res => {
			  this.$store.commit('changeKeyboardHeight',res.height)
			})
		},
		onShow: function() {
			this.$store.dispatch('reconnect')
			console.log('App Show')
		},
		onHide: function() {
			console.log('App Hide')
		}
	}
</script>

<style>
	/*每个页面公共css */
	@import "./common/free.css";
	@import "./common/common.css";
	/* #ifndef APP-PLUS-NVUE */
	@import "./common/free-icon.css";
	/* #endif */
	/* #ifdef MP */
	::-webkit-scrollbar{
		display: none;
	}
	/* #endif */
</style>
