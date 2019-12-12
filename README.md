# GSNAudioUnitGraphDemo
通过AudioUnit+AUGraph实现录音+耳返+保存录音到本地PCM

# Demo使用方法参考我的博客
CSDN：https://blog.csdn.net/weixin_43030741/article/details/103477017

掘金：https://juejin.im/post/5def4af26fb9a016544bd161

# Xcode版本问题
这个demo项目是在Xcode11兴建的，由于SceneDelegate的问题导致其无法在低于11的Xcode版本运行，但可以将项目中的GSNAudioUnitGraph.h和.m文件提取到自己的项目中便能轻松实现一个demo。
