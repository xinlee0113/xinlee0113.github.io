/**
 * 布局调试工具 - 类似Android的"显示布局边界"功能
 * 点击调试按钮即可开启/关闭布局边界显示
 */

(function() {
  'use strict';
  
  // 创建调试按钮
  function createDebugButton() {
    const button = document.createElement('button');
    button.id = 'layout-debug-toggle';
    button.innerHTML = '🔍 布局调试';
    button.style.cssText = `
      position: fixed;
      bottom: 20px;
      right: 20px;
      z-index: 999999;
      padding: 10px 15px;
      background: rgba(0, 0, 0, 0.8);
      color: white;
      border: 2px solid #4CAF50;
      border-radius: 5px;
      cursor: pointer;
      font-size: 14px;
      font-weight: bold;
      transition: all 0.3s ease;
      box-shadow: 0 2px 10px rgba(0,0,0,0.3);
    `;
    
    button.addEventListener('mouseenter', function() {
      this.style.background = 'rgba(0, 0, 0, 0.95)';
      this.style.transform = 'scale(1.05)';
    });
    
    button.addEventListener('mouseleave', function() {
      this.style.background = 'rgba(0, 0, 0, 0.8)';
      this.style.transform = 'scale(1)';
    });
    
    button.addEventListener('click', toggleDebugMode);
    document.body.appendChild(button);
  }
  
  // 切换调试模式
  function toggleDebugMode() {
    const existingStyle = document.getElementById('layout-debug-style');
    const button = document.getElementById('layout-debug-toggle');
    
    if (existingStyle) {
      // 关闭调试模式
      existingStyle.remove();
      button.innerHTML = '🔍 布局调试';
      button.style.borderColor = '#4CAF50';
    } else {
      // 开启调试模式
      const style = document.createElement('style');
      style.id = 'layout-debug-style';
      style.textContent = `
        /* 布局调试模式 - 类似Android显示布局边界 */
        * {
          outline: 1px solid rgba(255, 0, 0, 0.3) !important;
          background-color: rgba(255, 255, 0, 0.05) !important;
        }
        
        /* 不同层级用不同颜色 */
        * * {
          outline-color: rgba(0, 255, 0, 0.3) !important;
        }
        
        * * * {
          outline-color: rgba(0, 0, 255, 0.3) !important;
        }
        
        * * * * {
          outline-color: rgba(255, 0, 255, 0.3) !important;
        }
        
        * * * * * {
          outline-color: rgba(0, 255, 255, 0.3) !important;
        }
        
        /* 调试信息提示 */
        body::after {
          content: "红色=1层 | 绿色=2层 | 蓝色=3层 | 紫色=4层 | 青色=5层";
          position: fixed;
          top: 10px;
          left: 50%;
          transform: translateX(-50%);
          background: rgba(0, 0, 0, 0.9);
          color: white;
          padding: 8px 20px;
          border-radius: 20px;
          z-index: 999998;
          font-size: 12px;
          font-weight: bold;
          pointer-events: none;
        }
      `;
      document.head.appendChild(style);
      button.innerHTML = '✅ 调试开启';
      button.style.borderColor = '#FF5722';
    }
  }
  
  // 页面加载完成后创建按钮
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', createDebugButton);
  } else {
    createDebugButton();
  }
})();

