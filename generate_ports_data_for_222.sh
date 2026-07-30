
#!/bin/bash
# generate_data.sh - 生成容器数据 JSON

cd ~/ServerPorts.github.io

# 生成 JSON 数据
cat > containers.json << 'JSON_START'
{
  "generated": "",
  "containers": [
JSON_START

# 添加时间戳
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
sed -i "s/\"generated\": \"\",/\"generated\": \"$TIMESTAMP\",/" containers.json

# 从 docker ps 生成数据
docker ps -a --format "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.CreatedAt}}|{{.Ports}}" | while IFS='|' read -r id name image status created_at ports; do
    # 提取状态
    if [[ "$status" == *"Up"* ]]; then
        status_type="running"
        running_time=$(echo "$status" | sed 's/Up //')
    elif [[ "$status" == *"Exited"* ]]; then
        status_type="exited"
        running_time=$(echo "$status" | sed 's/Exited (.*) //' | sed 's/Exited //')
        if [ -z "$running_time" ]; then
            running_time=$(echo "$status" | sed 's/Exited //')
        fi
    elif [[ "$status" == *"Created"* ]]; then
        status_type="created"
        running_time=""
    else
        status_type="unknown"
        running_time="$status"
    fi
    
    # 处理端口
    if [ -z "$ports" ]; then
        ports_display="无"
    else
        ports_display=$(echo "$ports" | sed 's/, /,/g')
    fi
    
    # 处理创建时间
    created_display=$(echo "$created_at" | cut -d' ' -f1-3)
    
    # 写入 JSON
    cat >> containers.json << JSON_LINE
    {
        "id": "$id",
        "idShort": "${id:0:12}",
        "name": "$name",
        "image": "$image",
        "status": "$status_type",
        "statusFull": "$status",
        "runningTime": "$running_time",
        "createdAt": "$created_display",
        "ports": "$ports_display"
    },
JSON_LINE
done

# 移除最后一个逗号并结束 JSON
sed -i '$ s/,$//' containers.json
cat >> containers_222.json << 'JSON_END'
  ]
}
JSON_END

echo "✅ 数据已生成: containers_222.json"
echo "📊 容器数量: $(docker ps -a -q | wc -l)"
echo "🕐 时间: $(date)"
