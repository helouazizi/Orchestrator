if [ "$#" -ne 1 ]; then
    echo "Error: You must provide exactly 1 arguments. create | start | stop"
    exit 1
fi

case $1 in
    "create")
        echo "cluster created"
        vagrant up
        ;;
    "start")
        echo "cluster started"
        vagrant resume
        ;;
    "stop")
        echo "cluster stopped"
        vagrant suspend
        ;;
    "destroy")
        echo "cluster destroyed"
        vagrant destroy -f
        ;;
    *)
        echo "${1} is an unknown command"
        exit 1
        ;;
esac