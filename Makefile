CC		:= gcc
CFLAGS	:= -O3
ALGOS	:= qsort htable-list htable-tree binary-tree binary-tree-avl
LDFLAGS := -lpthread

RND_U32_CNT := 1000000
RND_U32_OUT := u32.$(RND_U32_CNT).rnd

RND_32B_CNT  := 1000000
RND_32B_OUT  := 32b.$(RND_32B_CNT).rnd

ifeq ($(DEBUG), 1)
CFLAGS := -O0 -g -DDEBUG=1
endif

ifeq ($(MAKE_VERBOSE), 1)
Q :=
else
Q := @
endif

HELPERS = __helpers.c dot.c

all: $(ALGOS)

qsort: qsort.c $(HELPERS)
	$(Q)$(CC) $^ $(CFLAGS) -o $@ $(LDFLAGS)

htable-list: htable.c $(HELPERS)
	$(Q)$(CC) $^ -DHTABLE_LIST $(CFLAGS) -o $@ $(LDFLAGS)

htable-tree: htable.c binary_tree.c $(HELPERS)
	$(Q)$(CC) $^ -DHTABLE_TREE $(CFLAGS) -o $@ $(LDFLAGS)

binary-tree: binary_tree.c $(HELPERS)
	$(Q)$(CC) $^ -DBINARY_TREE_MAIN $(CFLAGS) -o $@ $(LDFLAGS)

binary-tree-avl: binary_tree.c $(HELPERS)
	$(Q)$(CC) $^ -DBINARY_TREE_MAIN -DBINARY_TREE_AVL $(CFLAGS) -o $@ $(LDFLAGS)

.PHONY: rnd.u32 rnd.32b
rnd-u32:
	$(Q)dd if=/dev/urandom of=$(RND_U32_OUT) bs=$(RND_U32_CNT) count=4 &>/dev/null
rnd-32b:
	$(Q)dd if=/dev/urandom of=$(RND_32B_OUT) bs=$(RND_32B_CNT) count=32 &>/dev/null

test-qsort: qsort
	$(Q)dd if=/dev/urandom of=u32.100.rnd bs=100 count=4 &>/dev/null
	$(Q)./qsort -s QS1 -i 32b.100.rnd --dump
	$(Q)./qsort -s QS2 -i 32b.100.rnd --dump

test-htable: htable-list htable-tree
	$(Q)dd if=/dev/urandom of=32b.100.rnd bs=100 count=32 &>/dev/null
	$(Q)./htable-list -f simple -s 10 -i 32b.100.rnd -g htable-list.100.dot
	$(Q)dot -Tpng -o htable-list.100.png htable-list.100.dot
	$(Q)./htable-tree -f simple -s 10 -i 32b.100.rnd -g htable-tree.100.dot
	$(Q)dot -Tpng -o htable-tree.100.png htable-tree.100.dot

test-binary-tree: binary-tree binary-tree-avl
	$(Q)dd if=/dev/urandom of=u32.100.rnd bs=100 count=4 &>/dev/null
	$(Q)./binary-tree -i u32.100.rnd -g binary-tree.100.dot
	$(Q)dot -Tpng -o binary-tree.100.png binary-tree.100.dot
	$(Q)./binary-tree-avl -i u32.100.rnd -g binary-tree-avl.100.dot
	$(Q)dot -Tpng -o binary-tree-avl.100.png binary-tree-avl.100.dot

clean:
	$(Q)rm -rf $(ALGOS)
