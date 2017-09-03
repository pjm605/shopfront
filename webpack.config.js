var glob = require('glob');
var path = require('path');

// const HtmlWebpackPlugin = require('html-webpack-plugin');
// const HtmlWebpackPluginConfig = new HtmlWebpackPlugin({
// 	template: glob.sync("./app/template/*.html"),
// 	filename: '[name].html',
// 	inject: 'body'
// })


// module.exports = {
// 	entry: {'app' : glob.sync("./app/js/*.js"),},
// 	output: {
// 		path: path.join(__dirname, "/build/app/js"),
// 		filename: "[name].js"
// 	},
// 	module: {
// 		loaders: []
// 	},
// 	plugins: [HtmlWebpackPluginConfig]
	
// };
module.exports = {
	entry: {'app' : glob.sync("./app/js/*.js")},
	output: {
		path: path.join(__dirname, "/build/app/js"),
		filename: "[name].js"
	},
	module: {
		loaders: []
	}

};