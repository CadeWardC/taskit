AppSettingsPage({
  build(props) {
    let userId = props.settingsStorage.getItem("userId") || "";

    return Section({}, [
      View(
        {
          style: {
            marginTop: "30px",
            textAlign: "center",
          },
        },
        [
          Text(
            {
              style: {
                fontSize: "24px",
                fontWeight: "bold",
                color: "#BB86FC",
              },
            },
            ["TaskIt Settings"]
          ),
        ]
      ),

      View(
        {
          style: {
            marginTop: "30px",
            padding: "0 20px",
          },
        },
        [
          Text(
            {
              style: {
                fontSize: "16px",
                color: "#999999",
                marginBottom: "10px",
              },
            },
            ["User ID"]
          ),
          TextInput({
            label: "User ID",
            placeholder: "Enter your user ID",
            value: userId,
            subStyle: {
              fontSize: "18px",
            },
            onChange: (val) => {
              userId = val;
            },
          }),
        ]
      ),

      View(
        {
          style: {
            marginTop: "20px",
            textAlign: "center",
          },
        },
        [
          Button({
            label: "Save",
            color: "primary",
            onClick: () => {
              if (userId) {
                props.settingsStorage.setItem("userId", userId);
              }
            },
          }),
        ]
      ),

      View(
        {
          style: {
            marginTop: "30px",
            padding: "0 20px",
          },
        },
        [
          Text(
            {
              style: {
                fontSize: "14px",
                color: "#666666",
              },
            },
            [
              userId
                ? "Current User ID: " + userId
                : "No user ID set (using default: 1)",
            ]
          ),
        ]
      ),
    ]);
  },
});
