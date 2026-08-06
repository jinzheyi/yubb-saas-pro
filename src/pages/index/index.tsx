import React from 'react';
import { View, Text, Image } from '@tarojs/components';
import Taro from '@tarojs/taro';
import styles from './index.module.scss';

const Index: React.FC = () => {
  const handleClick = () => {
    Taro.showToast({ title: '开始体验', icon: 'success' });
  };

  return (
    <View className={styles.container}>
      <View className={styles.card}>
        <Text className={styles.logo}>🎉</Text>
        <Text className={styles.welcome}>欢迎使用 PAI 小程序</Text>
        <Text className={styles.desc}>基于 PAI 跨端技术构建的现代化小程序模板</Text>
        <View className={styles.button} onClick={handleClick}>
          <Text className={styles.buttonText}>开始体验</Text>
        </View>
      </View>
    </View>
  );
};

export default Index;
