# X2 メトリック設定一覧

このドキュメントは、X2で設定されているメトリックの一覧をまとめたものです。

## 設定ファイル

X2のメトリック設定は以下の2つのファイルに定義されています：

- [`product_metric_config_x2.yaml.jinja2`](../../ansible/playbooks/templates/metric_agent/product_metric_config_x2.yaml.jinja2) - カスタムメトリック設定
- [`metric_agent_config_uds_x2.yaml.jinja2`](../../ansible/playbooks/templates/metric_agent/metric_agent_config_uds_x2.yaml.jinja2) - 標準メトリック設定

## 参考情報

各メトリックの詳細な情報については、[autoware-metric-agent の README](https://github.com/tier4/autoware-metric-agent/blob/develop/README.md) を参照してください。

## メトリック設定状況

X2で設定されているメトリックカテゴリは以下の通りです。

| メトリックカテゴリ                           | X2での設定  |
| -------------------------------------------- | ----------- |
| acceleration                                 | ○           |
| accel_brake_map_calibration_status           | ○           |
| control_evaluation                           | ○           |
| diagnostics                                  | ○(詳細後述) |
| ekf_pose_error_ellipse                       | ○           |
| example_vehicle_steering_angle               | ×           |
| localization_scores                          | ○           |
| longitudinal_speed                           | ○           |
| multi_example_vehicle_steering_angle         | ×           |
| operation_mode                               | ○           |
| perception_analytics                         | ○           |
| planning_evaluation                          | ○           |
| polling_example_vehicle_steering_angle       | ×           |
| polling_multi_example_vehicle_steering_angle | ×           |
| polling_standard_message_topic_metric        | ×           |
| pose_instability                             | ○           |
| sample_metrics                               | ×           |
| standard_message_topic_metric                | ○           |
| system_monitor_cpu_usage                     | ○           |
| system_monitor_metrics                       | ○           |
| vehicle_geo_point                            | ○           |
| vehicle_status                               | ○           |

## diagnostics メトリック

`diagnostics` メトリックは、設定ファイル内で個別のキーとして定義されます。
X2では以下のキーが `metric_agent_config_uds_x2.yaml.jinja2` で設定されています。

| メトリック概要                                                                       | diagnostic_name                                                                  | diagnostic_key                                                                          |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| LiDARパケットロス (`lidar_packet_loss_{direction}_{height}`) (x8)                    | `/sensing/lidar/{direction}_{height}/hesai_ros_wrapper_node: Packet loss status` | `Lost packets`                                                                          |
| LiDARブロッケージ (`lidar_blockage_{area}_{direction}_{height}`) (x16)               | `blockage_return_diag: /sensing/lidar/{direction}_{height}: blockage_validation` | `{area}_blockage_ratio`                                                                 |
| LiDAR可視性 (`lidar_visibility_right_upper`)                                         | -                                                                                | -                                                                                       |
| LiDARフィルタ比 (`lidar_filter_ratio_right_upper`)                                   | -                                                                                | -                                                                                       |
| カメラパブリッシュレート (`camera{num}_publish_rate`) (x11)                          | `v4l2_camera_camera{num}: camera{num}_diagnostics`                               | `Publish rate`                                                                          |
| カメラブロッケージ (`camera3_blockage_ratio`, `camera5_blockage_ratio`) (x2)         | `image_diagnostics{num}: camera{num}`                                            | `{type}_ratio`                                                                          |
| カメラ低可視性 (`camera3_low_visibility_ratio`, `camera5_low_visibility_ratio`) (x2) | `image_diagnostics{num}: camera{num}`                                            | `{type}_ratio`                                                                          |
| LiDAR同期オフセット (`sync_diag_offset_main_sys_to_{direction}_{height}`) (x8)       | `sensor@{direction}_{height}/lidar`                                              | `upstream_links › main.sys -> {frame} › measurement › offset_from_main.sys › diff [ms]` |
| レーダー同期オフセット (`sync_diag_offset_main_sys_to_{position}_{direction}`) (x6)  | `sensor@{position}_{direction}/radar_link`                                       | `upstream_links › main.sys -> {frame} › measurement › offset_from_main.sys › diff [ms]` |
| IMUジャイロ補正 (`imu_gyro_{type}`) (x4)                                             | `gyro_bias_scale_validator: gyro_bias_scale_validator`                           | `estimated_gyro_{type}`                                                                 |

## カスタムメトリック

X2では、標準的なメトリックカテゴリに加えて、以下のカスタムメトリックが設定されています。これらのメトリックは `standard_message_topic_metric` カテゴリを使用しています。

| メトリック名                            | 説明                                       | 参照トピック名                                                      | custom_key                        |
| --------------------------------------- | ------------------------------------------ | ------------------------------------------------------------------- | --------------------------------- |
| vehicle_interface_steering_wheel_torque | ステアリングホイールトルクデータ           | `/vehicle/metrics/steering_wheel_torque`                            | `steering_wheel_torque`           |
| ndt_scan_matcher_execution_time         | NDTスキャンマッチャーノードの実行時間 (ms) | `/localization/pose_estimator/exe_time_ms`                          | `ndt_scan_matcher_execution_time` |
| ndt_scan_matcher_iteration_num          | NDTスキャンマッチャーノードの反復計算回数  | `/localization/pose_estimator/iteration_num`                        | `ndt_scan_matcher_iteration_num`  |
| whole_pipeline_latency                  | 全体パイプラインのレイテンシ (ms)          | `/system/pipeline_latency_monitor/output/total_latency_ms`          | -                                 |
| planning_pipeline_latency               | プランニングパイプラインのレイテンシ (ms)  | `/system/pipeline_latency_monitor/debug/planning_latency_ms`        | -                                 |
| control_pipeline_latency                | 制御パイプラインのレイテンシ (ms)          | `/system/pipeline_latency_monitor/debug/control_latency_ms`         | -                                 |
| accel_brake_map_error                   | アクセルブレーキマップエラー               | `/vehicle/calibration/accel_brake_map_calibrator/current_map_error` | -                                 |
| steering_offset_error                   | ステアリングオフセットエラー (rad)         | `/vehicle/calibration/steer_offset_estimator/steering_offset_error` | -                                 |
| speed_scale_factor_error                | 速度スケールファクターエラー               | `/sensing/calibration/deviation_estimator/speed_scale_factor_error` | -                                 |
