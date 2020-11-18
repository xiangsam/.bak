#source ~/peda/peda.py
source ~/pwndbg/gdbinit.py
source ~/Pwngdb/pwngdb.py
source ~/Pwngdb/angelheap/gdbinit.py
define hook-run
python
import angelheap
angelheap.init_angelheap()
end
end

参考文章: https://blog.csdn.net/weixin_43092232/article/details/105648769
