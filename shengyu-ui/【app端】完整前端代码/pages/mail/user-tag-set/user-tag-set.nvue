<template>
	<view class="page">
		<!-- 导航栏 -->
		<free-nav-bar title="添加标签" showBack :showRight="true" bgColor="bg-white">
			<free-main-button name="保存" slot="right" @click="save"></free-main-button>
		</free-nav-bar>
		
		<view class="px-3 pt-3 pb-2 border-bottom flex align-center flex-wrap">
			<view class="border border-main rounded-circle py-1 px-2 flex align-center justify-center mr-1 mb-1" v-for="(item,index) in list" :key="index" @click="delTag(index)">
				<text class="font main-text-color">{{item}}</text>
			</view>
			
			<input type="text" class="border bg-white font rounded-circle text-center" placeholder="添加标签" style="border-style: dashed;width: 180rpx;" v-model="tag" @confirm="addTag" confirm-type="send"/>
			
		</view>
		
		<view class="flex flex-column">
			<text class="font-sm text-secondary px-3 py-2">所有标签</text>
			<view class="px-3 flex align-center flex-wrap pt-3 pb-2">
				<view class="border bg-white rounded-circle px-2 py-1 mr-1 mb-1" v-for="(item,index) in allList" :key="index" @click="fastAddTag(item)">
					<text class="font text-dark">{{item}}</text>
				</view>
			</view>
		</view>
		
	</view>
</template>

<script>
	import freeNavBar from '@/components/free-ui/free-nav-bar.vue';
	import freeMainButton from '@/components/free-ui/free-main-button.vue';
	export default {
		components: {
			freeNavBar,
			freeMainButton
		},
		data() {
			return {
				tag:"",
				list:[],
				allList:["哈哈哈",'家人','亲戚','朋友','好友']
			}
		},
		onLoad(e) {
			if (e.detail) {
				this.list = JSON.parse(e.detail)
			}
		},
		methods: {
			// 保存
			save(){
				uni.$emit('updateTag',this.list)
				uni.navigateBack({
					delta: 1
				});
			},
			// 增加标签
			addTag(){
				if (this.tag === '') {
					return;
				}
				if(this.list.indexOf(this.tag) !== -1){
					this.tag = ''
					return uni.showToast({
						title: '标签已存在',
						icon: 'none'
					});
				}
				this.list.push(this.tag)
				this.tag = ''
			},
			// 快捷增加标签
			fastAddTag(item){
				if(this.list.indexOf(item) !== -1){
					return uni.showToast({
						title: '标签已存在',
						icon: 'none'
					});
				}
				this.list.push(item)
			},
			// 删除标签
			delTag(index){
				uni.showModal({
					content: '是否要删除该标签？',
					success:(res)=> {
						if (res.confirm) {
							this.list.splice(index,1)
						}
					}
				});
			}
		}
	}
</script>

<style>

</style>
