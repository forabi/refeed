module.exports = {
    "port": process.env.OPENSHIFT_NODEJS_PORT,
    "ip": process.env.OPENSHIFT_NODEJS_IP,
    "dirs": {
        "root": process.env.OPENSHIFT_DATA_DIR
    }
}