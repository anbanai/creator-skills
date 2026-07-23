# ecommerce Examples

### Case 1: 茶叶全套素材

- Input: 上传干茶、茶汤、叶底、包装 4 张图，选择主图+详情页。
- Recommended path: 先建 product-bible，再做 FABE 文案，最后按部位选参考图生成各模块。
- Artifacts: product-bible.md、copywriting.md、asset-plan.md、manifest.json。
- Quality gate: 每张电商图都带相关产品 ref，不允许纯文生图臆造商品。

### Case 2: 只生成分享图

- Input: 任务 selected_modules 只勾选 share。
- Recommended path: 跳过主图/详情/SKU，仍先做产品分析和合规检查。
- Artifacts: share_01.png、manifest.json。
- Quality gate: 未勾选模块不得生成，manifest 只列 share。

### Case 3: 复杂包装的参考素材选择

- Input: 复杂包装文字且有正面、侧面、细节等多张产品素材。
- Recommended path: 按当前页面职责选择真正相关的产品素材；参考图按语义相关性排序，prompt 点名每张图要保持的事实。服务端负责路由与数量限制，Agent 不按供应商或模型切换流程。
- Artifacts: best-refs.md、risk-notes.md。
- Quality gate: 不得把无关素材塞进当前页面；参考不足时记录事实缺口，不臆造商品细节。
