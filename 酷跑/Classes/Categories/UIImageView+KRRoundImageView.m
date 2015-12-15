//
//  UIImageView+KRRoundImageView.m
//  酷跑
//
//  Created by mis on 15/12/8.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "UIImageView+KRRoundImageView.h"

@implementation UIImageView (KRRoundImageView)

-(void)setRoundLayer
{
    //设置圆形头像
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = self.bounds.size.width/2;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor whiteColor].CGColor;

}

@end
