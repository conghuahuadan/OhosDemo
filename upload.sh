ohpm install --all --registry https://ohpm.openharmony.cn/ohpm/ --strict_ssl true
hvigorw --sync -p product=default --analyze=normal --parallel --incremental --daemon
hvigorw assembleHap -p product=internal -p buildMode=debug
groovy upload_hap.groovy