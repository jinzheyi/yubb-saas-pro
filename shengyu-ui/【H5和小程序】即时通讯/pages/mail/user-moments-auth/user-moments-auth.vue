<template>
	<view class="page">
		<!-- 导航栏 -->
		<free-nav-bar title="设置朋友圈动态权限" showBack :showRight="false">
		</free-nav-bar>
		<free-list-item title="不让他看我" :showLeftIcon="false"
		showRight :showRightIcon="false">
			<switch slot="right" :checked="!!form.lookme" color="#08C060" @change="change('lookme')"/>
		</free-list-item>
		<free-list-item title="不看他" :showLeftIcon="false"
		showRight :showRightIcon="false">
			<switch slot="right" :checked="!!form.lookhim" color="#08C060" @change="change('lookhim')"/>
		</free-list-item>
	</view>
</template>

<script>
	import freeNavBar from '@/components/free-ui/free-nav-bar.vue';
	import freeListItem from '@/components/free-ui/free-list-item.vue';
	import $H from '@/common/free-lib/request.js';
	export default {
		components: {
			freeNavBar,
			freeListItem
		},
		data() {
			return {
				id:0,
				form:{
					lookme:1,
					lookhim:1
				}
			}
		},
		onLoad(e) {
			if(e.user_id){
				this.id = e.user_id
			}
			if(e.params){
				this.form = JSON.parse(e.params)
			}
		},
		methods: {
			change(key){
				this.form[key] = this.form[key] ? 0 : 1
				this.submit()
			},
			submit(){
				$H.post('/friend/setmomentauth/'+this.id,this.form).then(res=>{
					uni.showToast({
						title: '修改成功',
						icon: 'none'
					});
				})
			}
		}
	}
</script>

<style>

</style>
