<template>
	<view class="page">
		<!-- 导航栏 -->
		<free-nav-bar title="标签列表" showBack :showRight="false">
		</free-nav-bar>
		
		<free-list-item v-for="(item,index) in list" :key="index" :title="item.name" :showRight="true" @click="handle(item)"></free-list-item>
	</view>
</template>

<script>
	import freeNavBar from '@/components/free-ui/free-nav-bar.vue';
	import freeListItem from '@/components/free-ui/free-list-item.vue';
	import $H from '@/common/free-lib/request.js';
	import auth from '@/common/mixin/auth.js';
	import { mapState } from 'vuex'
	export default {
		mixins:[auth],
		components: {
			freeNavBar,
			freeListItem,
		},
		data() {
			return {
				list:[]
			}
		},
		computed: {
			
		},
		created() {
			this.getData()
		},
		// 监听下拉刷新
		onPullDownRefresh() {
			this.getData().then(res=>{
				uni.showToast({
					title: '刷新成功',
					icon: 'none'
				});
				uni.stopPullDownRefresh()
			})
		},
		methods: {
			getData(){
				return new Promise((result,reject)=>{
					$H.get('/tag/list').then(res=>{
						this.list = res
						result(res)
					})
				})
			},
			handle(item){
				uni.navigateTo({
					url: '../tag-read/tag-read?id='+item.id,
				});
			}
		}
	}
</script>

<style>

</style>
